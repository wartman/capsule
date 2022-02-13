package capsule2;

#if macro
  import haxe.macro.Context;
  import haxe.macro.Expr;
  import haxe.macro.Type;

  using Lambda;
  using haxe.macro.Tools;
  using capsule2.internal.Tools;
#end

class Tools {
  public static macro function getIdentifier(e) {
    var id = capsule2.internal.Builder.createIdentifier(e);
    return macro $v{id};
  }

  public static macro function getDependencies(expr:Expr) {
    return compileDependencies(expr);
  }

  #if macro
    // @todo: Not a great place for this. Ideally we'll DRY it up with the code
    //        in capsule2.internal.Builder.
    static function compileDependencies(expr:Expr) {
      var pos = expr.pos;
      return switch expr.expr {
        case EFunction(_, f):
          var deps = compileArgs(f.args.map(a -> a.type.toType()), pos);
          macro [ $a{deps.map(d -> macro $v{d})} ];
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
              throw 'assert';
          }
          
          compileDependencies(expr);
        default: switch Context.typeof(expr) {
          case TType(_, _):
            var ct = expr.resolveComplexType();
            var path = expr.toString().split('.');

            // This will throw an error if the correct number of params are not
            // found, which is all we want.
            Context.resolveType(ct, pos);

            compileDependencies(macro $p{path}.new);
          case TFun(args, _):
            var deps = compileArgs(args.map(a -> a.t), pos);
            macro [ $a{deps.map(d -> macro $v{d})} ];
          default:
            macro [];
        }
      }
    }

    static function compileArgs(args:Array<Type>, pos:Position):Array<String> {
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
        exprs.push(arg.toString());
      }
      return exprs;
    }
  #end
}
