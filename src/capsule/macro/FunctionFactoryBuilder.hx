#if macro
package capsule.macro;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.ds.Map;

using Lambda;
using haxe.macro.Tools;
using capsule.macro.Common;

// TODO: DRY this with TypeFactoryBuilder.
class FunctionFactoryBuilder {

  static final container:String = 'c';

  var func:Expr;

  public function new(func:Expr) {
    this.func = func;
  }

  public function exportFactory():Expr {
    var body:Array<Expr> = [];

    switch (func.expr) {
      case EFunction(_, f):
        if (f.args.length == 0) {
          return macro _ -> ${func}();
        } else {
          var args = getArgs(f, new Map());
          body.push(macro return ${func}($a{args}));
        }
      default: switch (Context.typeof(func)) {
        case TFun(args, ret):

          // // Going to have to figure out a lot of junk to get
          // // metadata access I think:
          // var f = Context.typeExpr(func);
          // trace(f.expr);
          // switch (f.expr) {
          //   case TLocal({ t: t }): trace(t);
          //   case TField({ t: TInst(cls, _) }, fa): trace(fa);
          //   default:
          // }

          if (args.length == 0) {
            return macro _ -> ${func}();
          } else {
            var args = getMethodArgs(args, new Map());
            body.push(macro return ${func}($a{args}));
          }
        default: 
          Context.error('Expected a function', func.pos);
      }
    }

    return macro ($container:capsule.Container) -> $b{body};
  }

  function getArgs(f:Function, paramMap:Map<String, Type>) {
    var args:Array<Expr> = [];
    for (arg in f.args) {
      var argMeta = arg.meta.find(m -> m.name == ':inject.tag');
      var argId = argMeta != null ? argMeta.params[0] : macro null;
      var argType = arg.type.toType().resolveType(paramMap);

      if (argMeta != null) {
        if (arg.meta.exists(m -> m.name == ':inject.skip')) {
          if (!arg.type.toType().isNullable()) {
            Context.error('Arguments marked with `@:inject.skip` must be optional.', Context.currentPos());
          }
          args.push(macro null);
          continue;
        }
      }
      args.push(macro $i{container}.__get($v{argType}, $argId));
    }
    return args;
  }

  function getMethodArgs(args:Array<{ name:String, t:Type }>, paramMap:Map<String, Type>) {
    var exprs:Array<Expr> = [];
    for (arg in args) {
      var argType = arg.t.resolveType(paramMap);
      exprs.push(macro $i{container}.__get($v{argType}, null));
    }
    return exprs;
  }

}
#end
