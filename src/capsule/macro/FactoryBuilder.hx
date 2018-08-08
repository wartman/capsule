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
  public function exportFactory():Expr {
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
          // todo
        default:
      }
    }

    var ctor = cls.constructor.get();
    var args:Array<Expr> = [];
    if (ctor.meta.has(':inject')) {
      var ctorMeta = ctor.meta.extract(':inject')[0];

      switch (ctor.expr().expr) {
        case TFunction(f):
          for (i in 0...f.args.length) {
            var arg = f.args[i];
            var ctorId = ctorMeta.params[i];
            if (ctorId != null) {
              switch (ctorId.expr) {
                // If marked explicitly `null`, will be
                // skipped by the injector.
                case EConst(CIdent('null')):
                  args.push(macro null);
                  continue;
                default:
              }
            } else {
              ctorId = {
                expr:EConst(CIdent('null')),
                pos: cls.pos
              };
            }
            var followedType = arg.v.t.getType();
            var ctorTypeId:Expr = {
              expr: EConst(CString(followedType)),
              pos: cls.pos
            };
            args.push(macro container.getValue($ctorTypeId, $ctorId));
          }
        default:
      }
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