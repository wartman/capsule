package capsule.macro;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.Tools;
using capsule.macro.MappingBuilder;
// using capsule.macro.TypeHelpers;

class FactoryBuilder {

  public static final MAPPING:String = '__m';
  public static final CONTAINER:String = '__c';
  private var type:Expr;

  public function new(type:Expr) {
    this.type = type;
  }

  public function exportAliases(callPos:Position) {
    var cls = getClassType(type);

    if (cls == null) return null;

    var realParams = extractParams(type);
    var exprs:Array<Expr> = [];
    
    if (realParams.length > 0) {
      for (i in 0...cls.params.length) {
        var type = cls.params[i].t.getTypeName();
        var real = realParams[i];
        switch (real) {
          case TPType(t):
            var alias = t.toString(); // is this right???
            exprs.push(macro @:pos(callPos) $i{CONTAINER}.mapType($v{type}).toFactory(c -> c.get($v{alias})));
          case TPExpr(e):
            exprs.push(macro @:pos(callPos) $i{CONTAINER}.mapType($v{type}).toValue(${e}));
          default:
        }
      }
      return macro @:pos(callPos) {
        var $CONTAINER = $i{MAPPING}.getClosure();
        $b{exprs};
      };
    }

    return null;
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
          var id = meta.params.length > 0 ? meta.params[0] : macro @:pos(field.pos) null;
          exprs.push(macro $p{[ "value", name ]} = container.getValue($v{idName}, $id));
        case FMethod(k):
          var meth = field.expr();
          var meta = field.meta.extract(':inject')[0];
          if (meta == null) continue;

          if (meta.params.length > 0) {
            Context.error('You cannot use tagged injections on methods. Use argument injections instead.', field.pos);
          }
          var args = getArgumentTags(meth);
          if (args.length == 0) continue;
          exprs.push(macro @:pos(callPos) $p{[ "value", field.name ]}($a{ args }));
        default:
      }
    }

    var postInjects:Array<{ order:Int, expr:Expr }> = [];

    for (field in fields) {
      switch (field.kind) {
        case FMethod(_):
          var meta = field.meta.extract(':inject.post')[0];
          if (meta == null) continue;
          if (field.meta.has(':inject')) {
            Context.error('`@:inject.post` and `@:inject` are not allowed on the same method', field.pos);
          }
          var order:Int = 0;
          if (meta.params.length > 0) {
            switch (meta.params[0].expr) {
              case EConst(CInt(v)): order = Std.parseInt(v);
              default:
                Context.error('`@:inject.post` only accepts integers as params', field.pos);
            }
          }
          switch (field.expr().expr) {
            case TFunction(f):
              if (f.args.length > 0) {
                Context.error('`@:inject.post` methods cannot have any arguments', field.pos);
              }
            default:
          }
          postInjects.push({
            order: order,
            expr: macro @:pos(callPos) $p{[ "value", field.name ]}()
          });
        default:
          var meta = field.meta.extract(':inject.post')[0];
          if (meta != null) {
            Context.error('Only methods may be marked with `@:inject.post`', field.pos);
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
    var args = getArgumentTags(ctor.expr());
    var make = { expr:ENew(tp, args), pos: type.pos };

    return macro function(container:capsule.Container) {
      var value = ${make};
      $b{exprs};
      return value;
    };
  }

  private function getArgumentTags(fun:TypedExpr) {
    var args:Array<Expr> = [];
    switch (fun.expr) {
      case TFunction(f):
        for (arg in f.args) {
          var argMeta = arg.v.meta.extract(':inject.tag');
          var argId = argMeta.length > 0 ? argMeta[0].params[0] : macro null;
          var argType = arg.v.t.followType().toString();

          if (argMeta.length == 0) {
            if (arg.v.meta.has(':inject.skip')) {
              if (!arg.v.t.isNullable()) {
                Context.error('Arguments marked with `@:inject.skip` must be optional.', fun.pos);
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
    var name = removeParams(type.getExprTypeName());
    return getType(Context.getType(name));
  }

  private function extractParams(type:Expr) {
    var type = type.getMappingType();
    switch (type) {
      case TPath(p): 
        return p.params;
      default:
    }
    return [];
  }

  private function removeParams(type:String) {
    var index = type.indexOf("<");
    return (index>-1) ? type.substr(0, index) : type;
  }

  private function getType(type:Type) {
    return switch(type) {
      case TInst(t, params):
        t.get();
      default: 
        null;
    }
  }

}