#if macro
package capsule.macro;

import haxe.ds.Map;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using StringTools;
using haxe.macro.Tools;
using capsule.macro.BuilderTools;

class ClassFactoryBuilder {

  static final container:String = 'c';
  static final inject:String = ':inject';
  static final skip:String = ':inject.skip';
  static final tag:String = ':inject.tag';
  static final post:String = ':inject.post';

  public static function create(type:Expr, mappingType:Type) {
    var exprs:Array<Expr> = [];
    var cls = getClassType(type);
    var fields = cls.fields.get();
    var tp:TypePath = { pack: cls.pack, name: cls.name };
    var mappedType = extractMappedType(mappingType);
    var paramMap = mapParams(mappedType);
    var postInjects:Array<{ order:Int, expr:Expr }> = [];
    resolveParentParams(cls, paramMap);
    
    if (cls.constructor == null) {
      Context.error('A constructor is required for class mappings', cls.pos);
    }

    for (field in fields) switch field.kind {

      case FVar(_, _) if (field.meta.has(inject)):
        var meta = field.meta.extract(inject)[0];
        var name = field.name;
        var tag = meta.params[0];
        var dep = IdentifierBuilder.createDependencyForType(field.type, tag, paramMap);
        exprs.push(macro @:pos(type.pos) value.$name = $i{container}.getMappingByDependency(${dep}).getValue($i{container}));
      
      case FMethod(k) if (field.meta.has(inject)):
        var meta = field.meta.extract(inject)[0];
        var name = field.name;
        if (meta.params.length > 0) {
          Context.error('You cannot use tagged injections on methods. Use argument injections instead.', field.pos);
        }
        var args = getArgumentTags(field.expr(), paramMap);
        exprs.push(macro @:pos(type.pos) value.$name($a{args}));

      case FMethod(_) if (field.meta.has(post)):
        var meta = field.meta.extract(post)[0];
        var name = field.name;
        if (field.meta.has(inject)) {
          Context.error('`@${post}` and `@${inject}` are not allowed on the same method', field.pos);
        }
        var order:Int = 0;
        if (meta.params.length > 0) {
          switch (meta.params[0].expr) {
            case EConst(CInt(v)): order = Std.parseInt(v);
            default:
              Context.error('`@${post}` only accepts integers as params', field.pos);
          }
        }
        switch (field.expr().expr) {
          case TFunction(f):
            if (f.args.length > 0) {
              Context.error('`@${post}` methods cannot have any arguments', field.pos);
            }
          default:
        }
        postInjects.push({
          order: order,
          expr: macro @:pos(Context.currentPos()) value.$name()
        });

      default:

    }

    if (postInjects.length > 0) {
      haxe.ds.ArraySort.sort(postInjects, (a, b) -> a.order - b.order);
      exprs = exprs.concat(postInjects.map(pi -> pi.expr));
    }

    var ctor = cls.constructor.get();
    if (ctor.meta.has(inject)) {
      Context.error('Constructors should not be marked with `@${inject}` -- they will be injected automatically. You may still use argument injections on them.', ctor.pos);
    }
    var args = getArgumentTags(ctor.expr(), paramMap);
    var make = { expr:ENew(tp, args), pos: type.pos };

    return macro @:pos(type.pos) function($container:capsule.Container) {
      var value = ${make};
      $b{exprs};
      return value;
    };
  }
  
  static function getClassType(expr:Expr):ClassType {
    var type = getType(expr);
    return switch type {
      case TInst(t, _):
        t.get();
      default: 
        Context.error('Type must be a class: ${type.toString()}', Context.currentPos());
        null;
    }
  }

  static function mapParams(type:Type, ?paramMap:Map<String, Type>):Map<String, Type> {
    if (paramMap == null) paramMap = new Map();
    switch type {
      case TInst(t, params):
        var cls = t.get();
        var clsName = t.toString();
        var clsParams = cls.params;
        for (i in 0...clsParams.length) {
          paramMap.set('${clsName}.${clsParams[i].name}', params[i]);
        }
      default:
    }
    return paramMap;
  }

  static function extractMappedType(type:Type) {
    return switch (type) {
      case TInst(t, params): params[0];
      default: null;
    }
  }

  static function resolveParentParams(cls:ClassType, paramMap:Map<String, Type>) {
    var clsParams = cls.params;

    function resolve(c:{ t:Ref<ClassType>, params:Array<Type> }) {
      var superName = c.t.toString() + '.';
      for (key in paramMap.keys()) {
        var name = key.replace(superName, '');
        for (param in clsParams) {
          if (param.name == name) {
            paramMap.set(param.t.toString(), paramMap.get(key));
          }
        }
      }
      resolveParentParams(c.t.get(), paramMap);
    }

    if (cls.superClass != null) resolve(cls.superClass);
    if (cls.interfaces != null && cls.interfaces.length > 0) {
      for (iface in cls.interfaces) resolve(iface);
    }
  }

  static function getType(type:Expr):Type {
    var name = type.resolveComplexType().toString();
    return Context.getType(removeParams(name));
  }

  static function removeParams(type:String) {
    var index = type.indexOf("<");
    return (index > -1) ? type.substr(0, index) : type;
  }
  
  static function getArgumentTags(fun:TypedExpr, paramMap:Map<String, Type>) {
    var args:Array<Expr> = [];
    switch (fun.expr) {
      case TFunction(f):
        for (arg in f.args) {
          var argMeta = arg.v.meta.extract(tag);
          if (argMeta.length == 0) {
            if (arg.v.meta.has(skip)) {
              if (!arg.v.t.isNullable()) {
                Context.error('Arguments marked with `@${skip}` must be optional.', fun.pos);
              }
              args.push(macro null);
              continue;
            }
          }
          
          var argId = argMeta.length > 0 ? argMeta[0].params[0] : macro null;
          var dep = IdentifierBuilder.createDependencyForType(arg.v.t, argId, paramMap);
          args.push(macro @:pos(Context.currentPos()) $i{container}.getMappingByDependency(${dep}).getValue($i{container}));
        }
      default: 
        Context.error('Invalid method type', fun.pos);
    }
    return args;
  }

}
#end
