package capsule;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using haxe.macro.Tools;

typedef ModuleInfo = {
  public final exports:Array<String>;
  public final requires:Array<String>;
  public final expr:Expr;
} 

class ContainerBuilder {
  public static function buildFromModules(values:Array<ExprOf<Module>>) {
    var modules = values.map(parseModule);
    var body:Array<Expr> = values.map(module -> macro ($module).provide(container));
    var exports = modules.map(m -> m.exports).flatten();
    var deps = modules.map(m -> m.requires).flatten();
    var uniqueDeps = [];
    var uniqueExports = [];
    var notSatisfied = [];

    for (dep in deps) {
      if (!uniqueDeps.contains(dep)) uniqueDeps.push(dep);
    }

    for (dep in uniqueDeps) {
      if (!exports.contains(dep)) notSatisfied.push(dep);
    }

    if (notSatisfied.length > 0) {
      Context.error(
        'Some dependencies were not satisfied and a Container could not be built. '
        + 'Add Modules that provide the following: [${notSatisfied.join(', ')}]',
        Context.currentPos()
      );
    }

    return macro {
      var container = new capsule.Container();
      $b{body};
      container;
    };
  }

  static function parseModule(e:ExprOf<Module>):ModuleInfo {
    var type = Context.typeof(e);
    if (!Context.unify(type, Context.getType('capsule.Module'))) {
      Context.error('${type.toString()} should be capsule.Module', e.pos);
      return null;
    }
    return switch type {
      case TInst(t, params):
        var cls = t.get();
        var fields = cls.fields.get();
        var exports = fields.find(f -> f.name == '__exports').expr();
        var requires = fields.find(f -> f.name == '__requires').expr();

        var exported:Array<String> = [];
        var required:Array<String> = [];

        switch exports.expr {
          case TArrayDecl(el): 
            for (e in el) switch e.expr {
              case TConst(TString(s)) if (!exported.contains(s)): 
                exported.push(s);
              default:
            }
          default:
        }

        switch requires.expr {
          case TArrayDecl(el): 
            for (e in el) switch e.expr {
              case TArrayDecl(el): for (e in el) switch e.expr {
                case TConst(TString(s)) if (!exported.contains(s) && !required.contains(s)):
                  required.push(s);
                default:
              }
              default:
            }
          default:
        }

        return {
          requires: required,
          exports: exported,
          expr: e
        };
      default:
        Context.error('Not a module', e.pos);
        null;
    }
  }
}
