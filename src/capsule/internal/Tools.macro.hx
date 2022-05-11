package capsule.internal;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

using haxe.macro.Tools;

class Tools {
  static public function typeToIdentifier(type:Type) {
    return type.toComplexType().toString();
  }

  static public function complexTypeToIdentifier(complexType:ComplexType) {
    // @note: We need to convert ComplexTypes to Types first and then back, as
    //        we need to ensure that we have the FULL type path.
    return typeToIdentifier(complexType.toType());
  }
  
  static public function typesToIdentifiers(args:Array<Type>, pos:Position):Array<String> {
    var exprs:Array<String> = [];
    for (arg in args) {
      switch arg {
        case TMono(t):
          Context.error(
            'Could not resolve an argument type. Ensure that you are mapping '
            + 'to a concrete type with no unresolved type parameters.',
            pos
          );
        default:
      }
      exprs.push(typeToIdentifier(arg));
    }
    return exprs;
  }

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
