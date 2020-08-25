package capsule.macro;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using Lambda;
using haxe.macro.Tools;
using capsule.macro.BuilderTools;

class FunctionFactoryBuilder { 
  static final container:String = 'c';

  public static function create(func:Expr) {
    var body:Array<Expr> = [];

    switch (func.expr) {
      case EFunction(_, f):
        if (f.args.length == 0) {
          return macro function (_) return ${func}();
        } else {
          var args = getArgs(f, new Map());
          body.push(macro return ${func}($a{args}));
        }
      default: 
        Context.error('Expected a function', func.pos);
    }

    return macro @:pos(func.pos) function ($container:capsule.Container) return $b{body};
  }

  static function getArgs(f:Function, paramMap:Map<String, Type>) {
    var args:Array<Expr> = [];
    for (arg in f.args) {
      if (arg.meta.exists(m -> m.name == ':inject.skip')) {
        if (!arg.type.toType().isNullable()) {
          Context.error('Arguments marked with `@:inject.skip` must be optional.', Context.currentPos());
        }
        args.push(macro null);
        continue;
      }
      
      var argMeta = arg.meta.find(m -> m.name == ':inject.tag');
      var argId = argMeta != null ? argMeta.params[0] : macro null;
      var dep = IdentifierBuilder.createDependencyForType(arg.type.toType(), Context.currentPos(), argId, paramMap);
      var pos = arg.value != null ? arg.value.pos : f.expr.pos;

      args.push(macro @:pos(pos) $i{container}.getMappingByDependency(${dep}).getValue($i{container}));
    }
    return args;
  }
}
