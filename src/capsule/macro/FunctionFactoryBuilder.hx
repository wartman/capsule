#if macro
package capsule.macro;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using Lambda;
using haxe.macro.Tools;

class FunctionFactoryBuilder {
  
  static final container:String = 'c';

  public static function create(func:Expr) {
    var body:Array<Expr> = [];

    switch (func.expr) {
      case EFunction(_, f):
        if (f.args.length == 0) {
          return macro _ -> ${func}();
        } else {
          var args = getArgs(f, new Map());
          body.push(macro return ${func}($a{args}));
        }
      default: 
        Context.error('Expected a function', func.pos);
    }

    return macro ($container:capsule.Container) -> $b{body};
  }

  static function getArgs(f:Function, paramMap:Map<String, Type>) {
    var args:Array<Expr> = [];
    for (arg in f.args) {
      if (arg.meta.exists(m -> m.name == ':inject.skip')) {
        if (!isNullable(arg.type.toType())) {
          Context.error('Arguments marked with `@:inject.skip` must be optional.', Context.currentPos());
        }
        args.push(macro null);
        continue;
      }
      
      var argMeta = arg.meta.find(m -> m.name == ':inject.tag');
      var argId = argMeta != null ? argMeta.params[0] : macro null;
      var dep = IdentifierBuilder.createDependencyForType(arg.type.toType(), argId, paramMap);

      args.push(macro $i{container}.getMappingByDependency(${dep}).getValue($i{container}));
    }
    return args;
  }

  
  static function isNullable(type:Type):Bool {
    switch (type) {
      // hmm.
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

}
#end
