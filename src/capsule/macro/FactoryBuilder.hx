package capsule.macro;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.TypeTools;
using capsule.macro.TypeHelpers;
using Lambda;

class FactoryBuilder {

  private var type:Expr;

  public function new(type:Expr) {
    this.type = type;
  }

  // This is a mess, but you get the idea.
  public function exportFactory(callPos:Position):Expr {
    var cls = getClassType(type);
    var fields = cls.fields.get();
    var exprs:Array<Expr> = [];
    var tp:TypePath = {
      pack: cls.pack,
      name: cls.name
    };

    for (field in fields) {
      switch (field.kind) {
        case FVar(_, _):
          var meta = field.meta.extract(':inject')[0];
          if (meta == null) continue;

          var name = field.name;
          var fieldType = getType(field.type);
          var idName = fieldType.pack.concat([ fieldType.name ]).join('.');
          var typeId:Expr = {
            expr: EConst(CString(idName)),
            pos: field.pos
          } 
          var id = meta.params.length > 0 ? meta.params[0] : macro @:pos(field.pos) null;
          exprs.push(macro $p{[ "value", name ]} = container.getValue($typeId, $id));
        case FMethod(k):
          var meth = field.expr();
          var meta = field.meta.extract(':inject')[0];
          if (meta == null) continue;

          if (meta.params.length > 0) {
            Context.error('You cannot use tagged injections on methods. Use argument injections instead.', field.pos);
          }
          var args = getArgumentInjectons(meth);
          if (args.length == 0) continue;
          exprs.push(macro @:pos(callPos) $p{[ "value", field.name ]}($a{ args }));
        default:
      }
    }

    var postInjects:Array<{ order:Int, expr:Expr }> = [];

    for (field in fields) {
      switch (field.kind) {
        case FMethod(_):
          var meta = field.meta.extract(':postInject')[0];
          if (meta == null) continue;
          if (field.meta.has(':inject')) {
            Context.error('`@:postInject` and `@:inject` are not allowed on the same method', field.pos);
          }
          var order:Int = 0;
          if (meta.params.length > 0) {
            switch (meta.params[0].expr) {
              case EConst(CInt(v)): order = Std.parseInt(v);
              default:
                Context.error('`@:postInject` only accepts integers as params', field.pos);
            }
          }
          switch (field.expr().expr) {
            case TFunction(f):
              if (f.args.length > 0) {
                Context.error('`@:postInject` methods cannot have any arguments', field.pos);
              }
            default:
          }
          postInjects.push({
            order: order,
            expr: macro @:pos(callPos) $p{[ "value", field.name ]}()
          });
        default:
          var meta = field.meta.extract(':postInject')[0];
          if (meta != null) {
            Context.error('Only methods may be marked with `@:postInject`', field.pos);
          }
      }
    }

    if (postInjects.length > 0) {
      haxe.ds.ArraySort.sort(postInjects, function (a, b) {
        var result = a.order - b.order;
        return result;
      });
      exprs = exprs.concat(postInjects.map(function (pi) return pi.expr));
    }

    var ctor = cls.constructor.get();
    if(ctor.meta.has(':inject')) {
      Context.error('Constructors should not be marked with `@:inject` -- they will be injected automatically. You may still use argument injections on them.', ctor.pos);
    }
    var args = getArgumentInjectons(ctor.expr());
    var make = { expr:ENew(tp, args), pos: type.pos };

    return macro function(container:capsule.Container) {
      var value = ${make};
      $b{exprs};
      return value;
    };
  }

  private function getArgumentInjectons(fun:TypedExpr) {
    var args:Array<Expr> = [];
    switch (fun.expr) {
      case TFunction(f):
        for (arg in f.args) {
          var argMeta = arg.v.meta.extract(':inject');
          var argId = argMeta.length > 0 ? argMeta[0].params[0] : macro null;
          var argType = arg.v.t.getType();

          if (argMeta.length == 0) {
            if (arg.v.meta.has(':noInject')) {
              if (!arg.v.t.isNullable()) {
                Context.error('Methods and constructors must either be injectable or must only have optional arguments.', fun.pos);
              }
              args.push(macro null);
              continue;
            }
          }

          var argTypeId:Expr = {
            expr: EConst(CString(argType)),
            pos: fun.pos
          };
          args.push(macro container.getValue($argTypeId, $argId));
        }
      default: 
        Context.error('Invalid method type', fun.pos);
    }
    return args;
  }

  private function getClassType(type:Expr):ClassType {
    var name = type.getExprTypeName();
    return getType(Context.getType(name));
  }

  private function getType(type:Type) {
    return switch(type) {
      case TInst(t, _):
        t.get();
      default: 
        null;
    }
  }

}