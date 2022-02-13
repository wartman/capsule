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
      case EFunction(_, _) | ECall(_, _): // continue
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
    return switch expr.expr {
      case EFunction(_, f):
        var deps = compileArgs(f.args.map(a -> a.type.toType()), pos);
        macro (container:capsule2.Container) -> ${expr}($a{deps});
      case ECall(e, params):
        var ct = expr.resolveComplexType();
        var path = e.toString().split('.');
        var expr = macro @:pos(pos) $p{path}.new;

        switch ct.toType() {
          case TInst(t, params):
            var conType = t.get().constructor.get().type.applyTypeParameters(t.get().params, params).toComplexType();
            var t:ComplexType = switch conType {
              case TFunction(args, _): TFunction(args, ct);
              default: throw 'assert';
            }
            expr = macro (${expr}:$t);
          default:
            // ??
            throw 'assert';
        }
        
        return createFactory(macro @:pos(pos) $expr, pos);
      default: switch Context.typeof(expr) {
        case TType(_, _):
          var ct = expr.resolveComplexType();
          var path = expr.toString().split('.');

          // This will throw an error if the correct number of params are not
          // found, which is all we want.
          Context.resolveType(ct, pos);

          return createFactory(macro @:pos(pos) $p{path}.new, pos);
        case TFun(args, _):
          var deps = compileArgs(args.map(a -> a.t), pos);
          macro (container:capsule2.Container) -> {
            var factory = ${expr};
            return factory($a{deps});
          };
        default:
          return macro (container:capsule2.Container) -> $expr;
      }
    }
  }

  static function compileArgs(args:Array<Type>, pos:Position):Array<Expr> {
    var exprs:Array<Expr> = [];
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
      exprs.push(macro container.getMappingById($v{id}).resolve());
    }
    return exprs;
  }
}