package capsule2.internal;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.Tools;
using capsule2.internal.Tools;

class Builder {
  public static function getComplexType(target:Expr) {
    return target.resolveComplexType();
  }

  public static function createIdentifier(expr:Expr) {
    return expr.resolveComplexType().toType().toString();
  }

  public static function createProvider(expr:Expr, ret:ComplexType, pos:Position) {
    switch expr.expr {
      case EFunction(_, _): // continue
      case ECall(e, _): switch Context.typeof(e) {
        case TFun(_, _):
          // Is an actual function call (hopefully)
          return macro new capsule2.provider.ValueProvider<$ret>(${expr}); 
        default: 
          // Is a generic type -- continue.
      }
      default: switch Context.typeof(expr) {
        case TType(_, _) | TFun(_, _): // continue
        default:
          // If not a function or type, default to using a ValueProvider.
          return macro new capsule2.provider.ValueProvider<$ret>(${expr}); 
      }
    }

    var factory = createFactory(expr, pos);
    return macro new capsule2.provider.FactoryProvider<$ret>(${factory});
  }

  public static function createFactory(expr:Expr, pos:Position) {
    function argsToExpr(id:String) {
      return macro container.getMappingById($v{id}).resolve();
    }

    return switch expr.expr {
      case EFunction(_, _):
        var deps = getDependencies(expr, pos).map(argsToExpr);
        macro (container:capsule2.Container) -> ${expr}($a{deps});
      case ECall(e, params):
        var expr = getConstructorFromCallExpr(expr, pos);
        return createFactory(macro @:pos(pos) $expr, pos);
      default: switch Context.typeof(expr) {
        case TType(_, _):
          var path = expr.toString().split('.');
          checkExprForCorrectTypeParams(expr, pos);
          return createFactory(macro @:pos(pos) $p{path}.new, pos);
        case TFun(args, _):
          var deps = getDependencies(expr, pos).map(argsToExpr);
          macro (container:capsule2.Container) -> {
            var factory = ${expr};
            return factory($a{deps});
          };
        default:
          return macro (container:capsule2.Container) -> $expr;
      }
    }
  }

  public static function getDependencies(expr:Expr, pos:Position):Array<String> {
    return switch expr.expr {
      case EFunction(_, f):
        return typesToIdentifiers(f.args.map(a -> a.type.toType()), pos);
      case ECall(e, params):
        var expr = getConstructorFromCallExpr(expr, pos);
        return getDependencies(macro @:pos(pos) $expr, pos);
      default: switch Context.typeof(expr) {
        case TType(_, _):
          var path = expr.toString().split('.');
          checkExprForCorrectTypeParams(expr, pos);
          return getDependencies(macro @:pos(pos) $p{path}.new, pos);
        case TFun(args, _):
          return typesToIdentifiers(args.map(a -> a.t), pos);
        default:
          return [];
      }
    }
  }

  static function checkExprForCorrectTypeParams(expr:Expr, pos:Position) {
    switch Context.typeof(expr) {
      case TType(_, _):
        var ct = expr.resolveComplexType();
        // Will throw an error if we don't have the right number of
        // type params.
        Context.resolveType(ct, pos);
      default:
    }
  }

  static function getConstructorFromCallExpr(expr:Expr, pos:Position):Expr {
    return switch expr.expr {
      case ECall(e, params):
        var ct = expr.resolveComplexType();
        var path = e.toString().split('.');
        var expr = macro @:pos(pos) $p{path}.new;

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

  static function typesToIdentifiers(args:Array<Type>, pos:Position):Array<String> {
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
      var id = arg.toString();
      exprs.push(id);
    }
    return exprs;
  }
}