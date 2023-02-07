package capsule.internal;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.Tools;
using capsule.internal.Tools;

function getComplexType(target:Expr) {
  return target.resolveComplexType();
}

function createIdentifier(expr:Expr) {
  return expr.resolveComplexType().complexTypeToIdentifier();
}

function createProvider(expr:Expr, ret:ComplexType, pos:Position) {
  switch expr.expr {
    case EFunction(_, _): 
      // continue
    case ECall(e, _): switch Context.typeof(e) {
      case TFun(_, _):
        // Is an actual function call (hopefully)
        return macro new capsule.provider.ValueProvider<$ret>(${expr}, { scope: Parent }); 
      default: 
        // Is a generic type -- continue.
    }
    default: switch Context.typeof(expr) {
      case TType(_, _) | TFun(_, _): 
        // continue
      default:
        // If not a function or type, default to using a ValueProvider.
        return macro new capsule.provider.ValueProvider<$ret>(${expr}, { scope: Parent }); 
    }
  }

  var factory = createFactory(expr, pos);
  return macro new capsule.provider.FactoryProvider<$ret>(${factory});
}

function createFactory(expr:Expr, pos:Position) {
  function argsToExpr(id:String) {
    return macro container.ensureMapping($v{id}).resolve();
  }

  return switch expr.expr {
    case EFunction(_, _):
      var deps = getDependencies(expr, pos).map(argsToExpr);
      macro (container:capsule.Container) -> ${expr}($a{deps});
    case ECall(e, params):
      var expr = getConstructorFromCallExpr(expr, pos);
      return createFactory(macro $expr, pos);
    default: switch Context.typeof(expr) {
      case TType(_, _):
        var path = expr.toString().split('.');
        checkExprForCorrectTypeParams(expr, pos);
        return createFactory(macro $p{path}.new, pos);
      case TFun(args, _):
        var deps = getDependencies(expr, pos).map(argsToExpr);
        macro function (container:capsule.Container) {
          var factory = ${expr};
          return factory($a{deps});
        };
      default:
        return macro (container:capsule.Container) -> $expr;
    }
  }
}

function getDependencies(expr:Expr, pos:Position):Array<String> {
  return switch expr.expr {
    case EFunction(_, f):
      return f.args.map(a -> a.type.toType()).typesToIdentifiers(pos);
    case ECall(e, params):
      var expr = getConstructorFromCallExpr(expr, pos);
      return getDependencies(macro $expr, pos);
    default: switch Context.typeof(expr) {
      case TType(_, _):
        var path = expr.toString().split('.');
        checkExprForCorrectTypeParams(expr, pos);
        return getDependencies(macro $p{path}.new, pos);
      case TFun(args, _):
        return args.map(a -> a.t).typesToIdentifiers(pos);
      default:
        return [];
    }
  }
}

private function checkExprForCorrectTypeParams(expr:Expr, pos:Position) {
  switch Context.typeof(expr) {
    case TType(_, _):
      var ct = expr.resolveComplexType();
      // @note: Will throw an error if we don't have the right number of
      // type params, which is all we're looking for.
      Context.resolveType(ct, pos);
    default:
  }
}

private function getConstructorFromCallExpr(expr:Expr, pos:Position):Expr {
  return switch expr.expr {
    case ECall(e, params):
      var ct = expr.resolveComplexType();
      var path = e.toString().split('.');
      var expr = macro $p{path}.new;

      return switch ct.toType() {
        case TInst(t, params):
          var conType = t.get().constructor.get().type.applyTypeParameters(t.get().params, params).toComplexType();
          var t:ComplexType = switch conType {
            case TFunction(args, _): TFunction(args, ct);
            default: throw 'assert';
          }
          macro (${expr}:$t);
        default:
          throw 'assert';
      }
    default: 
      throw 'assert';
  }
}
