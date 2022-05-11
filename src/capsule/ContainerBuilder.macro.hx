package capsule;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import capsule.MappingInfo;

using Lambda;
using haxe.macro.Tools;
using capsule.internal.Tools;

typedef ModuleInfo = {
  public final id:String;
  public final exports:Array<MappingInfo>;
  public final imports:Array<MappingInfo>;
  public final pos:Position;
}

class ContainerBuilder {
  public static function buildFromModules(values:Array<ExprOf<Module>>) {
    var modules = values.map(parseModuleExpr);
    var rootModules = modules.copy();
    var body:Array<Expr> = values.map(module -> macro @:privateAccess container.useModule($module));
    var satisfied:Array<String> = [];
    var errors:Array<String> = [];

    for (module in rootModules) processModule(module, modules, module.pos);

    for (module in modules) for (export in module.exports) {
      if (satisfied.contains(export.id)) {
        errors.push('The mapping ${export.id} in the module ${module.id} was already provided');
      } else {
        satisfied.push(export.id);
      }
    }

    for (module in modules) {
      for (export in module.exports) for (dependency in export.dependencies) {
        if (!satisfied.contains(dependency)) {
          errors.push('${export.id} requires ${dependency} in the module ${module.id}');
        }
      }
      for (child in module.imports) for (dependency in child.dependencies) {
        if (!satisfied.contains(dependency)) {
          errors.push('The module ${child.id} requires ${dependency} in the module ${module.id}');
        }
      }
    }

    if (errors.length > 0) {
      Context.error(
        'Some dependencies were not satisfied and a Container could not be built. '
        + 'Fix the following problems: [ ${errors.join(', ')} ]',
        Context.currentPos()
      );
    }

    return macro {
      var container = new capsule.Container();
      $b{body};
      container;
    };
  }

  static function processModule(module:ModuleInfo, modules:Array<ModuleInfo>, pos:Position) {
    for (child in module.imports) {
      if (modules.exists(m -> m.id == child.id)) {
        Context.error('The module [${child.id}] was already added.', pos);
      }

      var type = Context.getType(child.id);
      var info = parseModuleInfo(type, pos);

      modules.push(info);

      processModule(info, modules, pos);
    }
  }

  static function parseModuleExpr(e:ExprOf<Module>):ModuleInfo {
    var type = Context.typeof(e);
    return parseModuleInfo(type, e.pos);
  }

  static function parseModuleInfo(type:Type, pos:Position):ModuleInfo {
    if (!Context.unify(type, Context.getType('capsule.Module'))) {
      Context.error('${type.toString()} should be capsule.Module', pos);
    }

    var exports = parseModuleMappings(type, '__exports');
    var imports = parseModuleMappings(type, '__imports');

    return {
      id: type.toComplexType().toString(),
      exports: exports,
      imports: imports,
      pos: pos
    };
  }

  static function parseModuleMappings(type:Type, field:String):Array<MappingInfo> {
    return switch type {
      case TInst(t, params):
        var cls = t.get();
        var exports = cls.findField(field, false).expr();
        var out:Array<MappingInfo> = [];
        
        switch exports.expr {
          case TArrayDecl(el): for (expr in el) {
            out.push(exprToModuleMapping(expr));
          }
          default: throw 'assert';
        }

        out;
      default:
        [];
    }
  }

  static function exprToModuleMapping(expr:TypedExpr):MappingInfo {
    return switch expr.expr {
      case TObjectDecl(fields): 
        var id = fields.find(f -> f.name == 'id').expr;
        var deps = fields.find(f -> f.name == 'dependencies').expr;
        return {
          id: exprToString(id),
          dependencies: exprToArray(deps)
        };
      default:
        throw 'assert';
    }
  }

  static function exprToArray(expr:TypedExpr):Array<String> {
    return switch expr.expr {
      case TArrayDecl(el): el.map(exprToString);
      default: throw 'assert';
    }
  }

  static function exprToString(expr:TypedExpr):String {
    return switch expr.expr {
      case TConst(TString(s)): s;
      case TConst(TNull): null;
      default: throw 'assert';
    }
  }
}
