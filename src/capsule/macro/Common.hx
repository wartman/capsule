#if macro
package capsule.macro;

import haxe.macro.Type;

using haxe.macro.Tools;
using capsule.macro.Common;

class Common {

  public static function resolveType(type:Type, paramMap:Map<String, Type>):String {
    function resolve(type:Type):Type {
      var resolved = switch (type) {
        case TInst(t, params):
          if (params.length == 0) {
            type.followType();
          } else {
            TInst(t, params.map(resolve)).followType();
          }
        case TAbstract(t, params):
          if (params.length == 0) {
            type.followType();
          } else {
            TAbstract(t, params.map(resolve)).followType();
          }
        default: 
          type.followType();
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

  public static function followType(type:Type):Type {
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

  public static function isNullable(type:Type):Bool {
    switch (type) {
      // hmm.
      case TAbstract(t, inst):
        if (Std.string(t) == 'Null')
          return true;
        return false;
      case TType(t, params):
        if (Std.string(t) == 'Null')
          return true;
        return switch (t.get().type) {
          case TAnonymous(_): false;
          case ref: isNullable(ref);
        }
      default:
        return false;
    }
  }

}
#end
