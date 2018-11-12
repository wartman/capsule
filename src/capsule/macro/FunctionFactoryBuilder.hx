package capsule.macro;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.ds.Map;

using capsule.macro.Common;

// TODO: DRY this with TypeFactoryBuilder.
class FunctionFactoryBuilder {

  var func:Expr;

  public function new(func:Expr) {
    this.func = func;
  }

  public function exportFactory():Expr {
    var body:Array<Expr> = [];
    
    switch (Context.typeof(func)) {
      case TFun(args, ret):
        if (args.length == 0) {
          return macro _ -> ${func}();
        } else {
          var args = getArgs(args, new Map());
          body.push(macro return ${func}($a{args}));
        }
      default: 
        Context.error('Expected a function', func.pos);
    }

    return macro (c:capsule.Container) -> $b{body};
  }

  function getArgs(args:Array<{ name:String, t:Type }>, paramMap:Map<String, Type>) {
    var exprs:Array<Expr> = [];
    for (arg in args) {
      // todo: extract tags somehow?
      var argId = macro null;
      var argType = arg.t.resolveType(paramMap);
      exprs.push(macro c.__get($v{argType}, $argId));
    }
    return exprs;
  }

}
