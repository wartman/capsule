package capsule.macro;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.ds.Map;

using Lambda;
using tink.MacroApi;
using haxe.macro.Tools;
using capsule.macro.MappingBuilder;

// TODO: DRY this with TypeFactoryBuilder.
class FunctionFactoryBuilder {

  final funcName:String = '__f';
  var func:Expr;
  var mappingType:Type;

  public function new(func:Expr, mappingType:Type) {
    this.func = func;
    this.mappingType = mappingType;
  }

  public function exportFactory(callPos:Position):Expr {
    var body:Array<Expr> = [];
    var err = () -> Context.error('Expected a function', func.pos);
    
    switch (Context.typeof(func)) {
      case TFun(args, ret):
        if (args.length == 0) {
          return macro _ -> ${func}();
        } else {
          body = body.concat(getArgumentTags(args, new Map()));
          var callArgs = args.map(a -> macro $i{a.name});
          body.push(macro {
            var $funcName = ${func};
            return $i{funcName}($a{callArgs});
          });
        }
      default: err();
    }

    return macro (c:capsule.Container) -> $b{body};
  }

  function getArgumentTags(args:Array<{ name:String, t:Type }>, paramMap:Map<String, Type>) {
    var exprs:Array<Expr> = [];
    for (arg in args) {
      // var argMeta:MetadataEntry = arg.meta.find(m -> m.name == ':inject.tag');
      // var argId = argMeta != null ? argMeta.params[0] : macro null;
      var argId = macro null;
      var argType = resolveType(arg.t, paramMap);
      var name = arg.name;

      // if (arg.meta.exists(m -> m.name == ':inject.skip')) {
      //   if (!arg.type.toType().isNullable()) {
      //     Context.error('Arguments marked with `@:inject.skip` must be optional.', fun.pos);
      //   }
      //   exprs.push(macro var $name = null);
      //   continue;
      // }

      exprs.push(macro var $name = c.__get($v{argType}, $argId));
    }
    return exprs;
  }

  function resolveType(type:Type, paramMap:Map<String, Type>):String {
    function resolve(type:Type):Type {
      var resolved = switch (type) {
        case TInst(t, params):
          if (params.length == 0) {
            type.followType();
          } else {
            TInst(t, params.map(resolve)).followType();
          }
        case TAbstract(t, params):
          if (params.length == 0) {
            type.followType();
          } else {
            TAbstract(t, params.map(resolve)).followType();
          }
        default: 
          type.followType();
      }

      return if (paramMap.exists(resolved.toString())) {
        resolve(paramMap.get(resolved.toString()));
      } else {
        resolved;
      }
    }

    return resolve(type).toString();
  }


}