#if macro
package capsule.macro;

import haxe.ds.Map;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
using capsule.macro.BuilderTools;

class IdentifierBuilder {

  public static function create(
    type:Type,
    pos:Position,
    ?tag:ExprOf<String>,
    ?paramMap:Map<String, Type>
  ):ExprOf<capsule.Identifier> {
    var name = try {  
      typeToString(type, paramMap != null ? paramMap : []);
    } catch (e:Dynamic) {
      '';
    }
    if (tag == null) {
      tag = macro null;
    }
    var id = macro @:pos(pos) $v{name};
    return macro @:pos(pos) new capsule.Identifier(${id}, ${tag});
  }

  public static function createDependency(
    expr:Expr, 
    ?tag:ExprOf<String>,
    ?paramMap:Map<String, Type>
  ) {
    var type = expr.resolveComplexType().toType();
    return createDependencyForType(type, expr.pos, tag, paramMap);
  }

  public static function createDependencyForType(
    type:Type,
    pos:Position, 
    ?tag:ExprOf<String>,
    ?paramMap:Map<String, Type>
  ) {
    var name = try {  
      typeToString(type, paramMap != null ? paramMap : []);
    } catch (e:Dynamic) {
      '';
    }
    var ct = name.parseAsType();
    var id = macro @:pos(pos) $v{name};
    if (tag == null) {
      tag = macro null;
    }
    return macro @:pos(pos) (new capsule.Dependency(${id}, ${tag}):capsule.Dependency<$ct>);
  }

  static function typeToString(type:Type, paramMap:Map<String, Type>):String {
    function resolve(type:Type) {
      var resolved = switch type {
        case TType(t, params):
          if (params.length == 0) {
            followType(type);
          } else {
            followType(TType(t, params.map(resolve)));
          }
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
      var out = if (paramMap.exists(key)) {
        resolve(paramMap.get(key));
      } else {
        resolved;
      }
      
      return out;
    }

    return resolve(type).toString();
  }

  static function followType(type:Type):Type {
    return switch (type) {
      case TType(t, params) if (Std.string(t) == 'Null'):
        followType(params[0]);
      // case TType(t, params):
      //   if (Std.string(t) == 'Null') {
      //     followType(params[0]);
      //   } else switch (t.get().type) {
      //     case TAnonymous(_): type;
      //     case ref: followType(ref);
      //   }
      default: type;
    }
  }

}
#end
