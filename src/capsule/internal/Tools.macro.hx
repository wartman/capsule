package capsule.internal;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;

class Tools {
  static public function parseAsType(name:String):ComplexType {
    return switch Context.parse('(null:${name})', Context.currentPos()) {
      case macro (null:$type): type;
      default: null;
    }
  }
  
  static public function resolveComplexType(expr:Expr):ComplexType {
    return switch expr.expr {
      case ECall(e, params):
        var tParams = params.map(param -> resolveComplexType(param).toString()).join(',');
        parseAsType(resolveComplexType(e).toString() + '<' + tParams + '>');
      default: switch Context.typeof(expr) {
        case TType(_, _):
          parseAsType(expr.toString());
        default:
          Context.error('Invalid expression', expr.pos);
          null;
      }
    }
  }
}
