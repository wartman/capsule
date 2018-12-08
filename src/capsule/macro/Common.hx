#if macro
package capsule.macro;

import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.Tools;
using capsule.macro.Common;

class Common {

  public static function isTag(t:Type) {
    return Context.unify(t, Context.getType('capsule.Tag'));
  }

  public static function extractTagName(t:Type) return switch(t) {
    case TInst(t, params):
      switch (params[0]) {
        case TInst(_.get() => t, _):
          switch (t.kind) {
            case KExpr({expr: EConst(CString(argId)), pos: _}):
              argId;
            default:
              Context.error('Expected a string as the first param', Context.currentPos());
              '';
          }
        default:
          Context.error('Expected a Tag', Context.currentPos());
          '';
      }
    default:
      Context.error('Tag requires params', Context.currentPos());
      '';
  }
  
  public static function extractTagType(t:Type) return switch(t) {
    case TInst(t, params):
      params[1];
    default:
      Context.error('Tag requires params', Context.currentPos());
      null;
  }

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

      return if (paramMap.exists(resolved.toString())) {
        resolve(paramMap.get(resolved.toString()));
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
        return switch (t.get().type)
        {
          case TAnonymous(_): false;
          case ref: isNullable(ref);
        }
      default:
        return false;
    }
  }

}
#end
