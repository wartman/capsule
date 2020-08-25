package capsule.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

class BuilderTools {
  static public function isNullable(type:Type):Bool {
    switch type {
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

  static public function parseAsType(name:String):ComplexType {
    return switch Context.parse('(null:${name})', Context.currentPos()) {
      case macro (null:$type): type;
      default: null;
    }
  }
  
  static public function resolveComplexType(expr:Expr):ComplexType {
    return switch expr.expr {
      case EConst(CString(s)):
        parseAsType(s);
      default: switch Context.typeof(expr) {
        case TType(_, _):
          parseAsType(expr.toString());
        default:
          Context.error('Invalid expression: expected a string or type', expr.pos);
          null;
      }
    }
  }
}
