#if macro
package capsule.refactor.macro;

import haxe.ds.Map;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

class IdentifierBuilder {

  public static function create(type:Type, ?tag:ExprOf<String>, ?paramMap:Map<String, Type>):ExprOf<Identifier> {
    var name = try {  
      typeToString(type, paramMap != null ? paramMap : []);
    } catch (e:Dynamic) {
      '';
    }
    return macro new capsule.refactor.Identifier($v{name}, ${tag});
  }

  public static function createDependency(expr:Expr, ?tag:ExprOf<String>, ?paramMap:Map<String, Type>) {
    if (tag == null) tag = exprToTag(expr);
    var type = exprToType(expr).toType();
    return createDependencyForType(type, tag, paramMap);
  }

  public static function createDependencyForType(type:Type, ?tag:ExprOf<String>, ?paramMap:Map<String, Type>) {
    var name = try {  
      typeToString(type, paramMap != null ? paramMap : []);
    } catch (e:Dynamic) {
      '';
    }
    var ct = parseType(name, Context.currentPos());
    return macro (new capsule.refactor.Dependency($v{name}, ${tag}):capsule.refactor.Dependency<$ct>);
  }

  public static function exprToTag(expr:Expr):Null<ExprOf<String>> {
    return switch expr.expr {
      case EVars(vars):
        if (vars.length > 1) {
          Context.error('Only one var should be used here', expr.pos);
        }
        macro $v{vars[0].name};
      default: null;
    }
  }

  public static function exprToType(expr:Expr):ComplexType {
    return switch expr.expr {
      case EConst(CString(s)):
        parseType(s, expr.pos);
      case EVars(vars):
        if (vars.length > 1) {
          Context.error('Only one var should be used here', expr.pos);
        }
        vars[0].type;
      default:
        switch Context.typeof(expr) {
          case TType(_, _):
            return parseType(expr.toString(), expr.pos);
          default: 
            null;
        }
    }
  }

  static function typeToString(type:Type, paramMap:Map<String, Type>):String {
    function resolve(type:Type) {
      var resolved = switch type {
        case TInst(t, params): 
          if (params.length == 0) {
            followType(type);
          } else {
            followType(TInst(t, params.map(resolve)));
          }
        case TAbstract(t, params):
          if (params.length == 0) {
            followType(type);
          } else {
            followType(TAbstract(t, params.map(resolve)));
          }
        default:
          followType(type);
      }

      var key = resolved.toString();
      return if (paramMap.exists(key)) {
        resolve(paramMap.get(key));
      } else {
        resolved;
      }
    }

    return resolve(type).toString();
  }

  static function followType(type:Type):Type {
    return switch (type) {
      case TType(t, params):
        if (Std.string(t) == 'Null') {
          followType(params[0]);
        } else switch (t.get().type) {
          case TAnonymous(_): type;
          case ref: followType(ref);
        }
      default: type;
    }
  }

  static function parseType(name:String, pos:Position):ComplexType {
    return switch(Context.parse('(null:${name})', pos)) {
      case macro (null:$type): type;
      default: null;
    }
  }

}
#end
