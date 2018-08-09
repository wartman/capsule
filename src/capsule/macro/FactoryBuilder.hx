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
      var meta = field.meta.extract(':inject');
      // todo: check for `:post`
      if (meta.length == 0) continue;

      switch (field.kind) {
        case FVar(_, _):
          var name = field.name;
          var fieldType = getType(field.type);
          var idName = fieldType.pack.concat([ fieldType.name ]).join('.');
          var typeId:Expr = {
            expr: EConst(CString(idName)),
            pos: field.pos
          } 
          var id = meta[0].params.length > 0 ? meta[0].params[0] : {
            expr:EConst(CIdent('null')),
            pos: field.pos
          };
          exprs.push(macro $p{[ "value", name ]} = container.getValue($typeId, $id));
        case FMethod(k):
          // todo. Probably can reuse the code I have for the constructor?
        default:
      }
    }

    var ctor = cls.constructor.get();
    var args:Array<Expr> = [];
    var globalInject = ctor.meta.has(':inject');
    if (globalInject) {
      var globalMeta = ctor.meta.extract(':inject')[0];
      if (globalMeta.params.length != 0) {
        trace(globalMeta);
        Context.error('Inject metadata cannot have arguments when being used on a constructor. Mark individual arguments with `@:inject("id")` instead.', ctor.pos);
      }
    }

    switch (ctor.expr().expr) {
      case TFunction(f):
        for (arg in f.args) {
          var argMeta = arg.v.meta.extract(':inject');
          var argId = argMeta.length > 0 ? argMeta[0].params[0] : macro null;
          var argType = arg.v.t.getType();

          if (argMeta.length == 0) {
            if (!globalInject && !arg.v.t.isNullable()) {
              Context.error('Construtors must either be injectable or must only have optional arguments.', callPos);            
            } else if (!globalInject) {
              args.push(macro null);
              continue;
            }
          }

          var argTypeId:Expr = {
            expr: EConst(CString(argType)),
            pos: cls.pos
          };
          args.push(macro container.getValue($argTypeId, $argId));
        }
      default:
    }

    // todo: allow constructor injection
    var make = { expr:ENew(tp, args), pos: type.pos };

    // TODO:
    // Need to check the type of Value much sooner, as this will 
    // throw weird.
    return macro function(container:capsule.Container) {
      var value = ${make};
      $b{exprs};
      return value;
    };
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