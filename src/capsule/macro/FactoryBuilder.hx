package capsule.macro;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.ds.Map;

using StringTools;
using haxe.macro.Tools;
using capsule.macro.MappingBuilder;

class FactoryBuilder {

  private var type:Expr;
  private var mappingType:Type;

  public function new(type:Expr, mappingType:Type) {
    this.type = type;
    this.mappingType = mappingType;
  }

  // This is a mess, but you get the idea.
  public function exportFactory(callPos:Position):Expr {
    var cls = getClassType(type);
    var fields = cls.fields.get();
    var mappedType = extractMappedType(mappingType);
    var paramMap = mapParams(mappedType);
    resolveParentParams(cls, paramMap);
    var exprs:Array<Expr> = [];
    var tp:TypePath = {
      pack: cls.pack,
      name: cls.name
    };

    for (field in fields) {
      switch (field.kind) {
        case FVar(_, _):
          var meta = field.meta.extract(':inject')[0];
          if (meta == null) continue;
          var name = field.name;
          var key = resolveType(field.type, paramMap);
          var tag = meta.params.length > 0 ? meta.params[0] : macro @:pos(field.pos) null;
          exprs.push(macro $p{[ "value", name ]} = container.getValue($v{key}, $tag));
        case FMethod(k):
          var meth = field.expr();
          var meta = field.meta.extract(':inject')[0];
          if (meta == null) continue;

          if (meta.params.length > 0) {
            Context.error('You cannot use tagged injections on methods. Use argument injections instead.', field.pos);
          }

          var args = getArgumentTags(meth, paramMap);
          if (args.length == 0) continue;
          exprs.push(macro @:pos(callPos) $p{[ "value", field.name ]}($a{ args }));
        default:
      }
    }

    var postInjects:Array<{ order:Int, expr:Expr }> = [];

    for (field in fields) {
      switch (field.kind) {
        case FMethod(_):
          var meta = field.meta.extract(':inject.post')[0];
          if (meta == null) continue;
          if (field.meta.has(':inject')) {
            Context.error('`@:inject.post` and `@:inject` are not allowed on the same method', field.pos);
          }
          var order:Int = 0;
          if (meta.params.length > 0) {
            switch (meta.params[0].expr) {
              case EConst(CInt(v)): order = Std.parseInt(v);
              default:
                Context.error('`@:inject.post` only accepts integers as params', field.pos);
            }
          }
          switch (field.expr().expr) {
            case TFunction(f):
              if (f.args.length > 0) {
                Context.error('`@:inject.post` methods cannot have any arguments', field.pos);
              }
            default:
          }
          postInjects.push({
            order: order,
            expr: macro @:pos(callPos) $p{[ "value", field.name ]}()
          });
        default:
          var meta = field.meta.extract(':inject.post')[0];
          if (meta != null) {
            Context.error('Only methods may be marked with `@:inject.post`', field.pos);
          }
      }
    }

    if (postInjects.length > 0) {
      haxe.ds.ArraySort.sort(postInjects, function (a, b) {
        var result = a.order - b.order;
        return result;
      });
      exprs = exprs.concat(postInjects.map(function (pi) return pi.expr));
    }

    var ctor = cls.constructor.get();
    if(ctor.meta.has(':inject')) {
      Context.error('Constructors should not be marked with `@:inject` -- they will be injected automatically. You may still use argument injections on them.', ctor.pos);
    }
    var args = getArgumentTags(ctor.expr(), paramMap);
    var make = { expr:ENew(tp, args), pos: type.pos };

    return macro function(container:capsule.Container) {
      var value = ${make};
      $b{exprs};
      return value;
    };
  }

  private function getArgumentTags(fun:TypedExpr, paramMap:Map<String, Type>) {
    var args:Array<Expr> = [];
    switch (fun.expr) {
      case TFunction(f):
        for (arg in f.args) {
          var argMeta = arg.v.meta.extract(':inject.tag');
          var argId = argMeta.length > 0 ? argMeta[0].params[0] : macro null;
          var argType = resolveType(arg.v.t, paramMap);

          if (argMeta.length == 0) {
            if (arg.v.meta.has(':inject.skip')) {
              if (!arg.v.t.isNullable()) {
                Context.error('Arguments marked with `@:inject.skip` must be optional.', fun.pos);
              }
              args.push(macro null);
              continue;
            }
          }

          args.push(macro container.getValue($v{argType}, $argId));
        }
      default: 
        Context.error('Invalid method type', fun.pos);
    }
    return args;
  }

  private function getClassType(type:Expr):ClassType {
    var type = getType(type);
    return extractClassType(type);
  }

  private function extractClassType(type:Type):ClassType {
    return switch(type) {
      case TInst(t, params):
        t.get();
      default: 
        Context.error('Type must be a class: ${type.toString()}', Context.currentPos());
        null;
    }
  }

  private function extractMappedType(type:Type) {
    return switch (type) {
      case TInst(t, params): params[0];
      default: null;
    }
  }
  
  private function mapParams(type:Type, ?paramMap:Map<String, Type>):Map<String, Type> {
    if (paramMap == null) paramMap = new Map();
    switch (type) {
      case TInst(t, params):
        var cls = t.get();
        var clsName = t.toString(); // ?
        var clsParams = cls.params;
        for (i in 0...clsParams.length) {
          paramMap.set('${clsName}.${clsParams[i].name}', params[i]);
        }
      default:
    }
    return paramMap;
  }

  private function resolveParentParams(cls:ClassType, paramMap:Map<String, Type>) {
    if (cls.superClass == null) return;
    var clsParams = cls.params;
    var superT = cls.superClass.t;
    var superTName = superT.toString() + '.';
    for (key in paramMap.keys()) {
      var name = key.replace(superTName, '');
      for (param in clsParams) {
        if (param.name == name) {
          paramMap.set(param.t.toString(), paramMap.get(key));
        }
      }
    }
    resolveParentParams(cls.superClass.t.get(), paramMap);
  }

  private function resolveType(type:Type, paramMap:Map<String, Type>):String {
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

  private function removeParams(type:String) {
    var index = type.indexOf("<");
    return (index>-1) ? type.substr(0, index) : type;
  }

  private function getType(type:Expr):Type {
    var name = removeParams(type.getExprTypeName());
    return Context.getType(name);
  }

}