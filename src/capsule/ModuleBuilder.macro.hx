package capsule;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using haxe.macro.Tools;
using capsule.internal.Tools;

typedef TrackedMapping = {
  public var ?id:Expr;
  public var ?concrete:Expr;
}; 

class ModuleBuilder {
  public static function build() {
    var fields = Context.getBuildFields();
    var cls = Context.getLocalClass().get();
    var provider = fields.find(f -> f.name == 'provide');
    var containerName = 'container';
    var exports:Array<TrackedMapping> = [];
    var currentMapping:Null<TrackedMapping> = null;
    var imports:Array<Expr> = [];

    if (cls.superClass != null) {
      Context.error(
        'Modules are currently not allowed to extend other classes.',
        cls.pos
      );
    }

    if (cls.params.length > 0) {
      Context.error(
        'Modules are currently not allowed to be generic/use type params.',
        cls.pos
      );
    }

    // If `provide` doesn't exist yet, let Haxe complain.
    if (provider == null) return fields;
    
    function findMappings(e:Expr) {
      switch e.expr {
        case ECall(e, params): switch e.expr {
          case EField(e, 'use'):
            imports = imports.concat(params);
            for (param in params) exports.push({ id: null, concrete: param });
          case EField(e, 'to'):
            currentMapping = { concrete: params[0] };
            findMappings(e);
          case EField(e, 'map') if (currentMapping != null):
            currentMapping.id = params[0];
            findMappings(e);
          default:
            findMappings(e);
        }
        case EConst(CIdent(c)) if (c == containerName && currentMapping != null):
          exports.push(currentMapping);
          currentMapping = null;
        default:
          e.iter(findMappings);
      }
    }

    // @todo: We need some way of ensuring that mapping ONLY happens in the
    //        `provide` function, as we don't track it anywhere else.
    switch provider.kind {
      case FFun(f):
        var expr = f.expr;
        containerName = f.args[0].name; // Ensure we have the right identifier.

        findMappings(expr);
        fields = fields.concat((macro class {
          @:keep public static final __exports:Array<capsule.ModuleMapping> = [
            $a{exports.filter(m -> m.id != null).map(m -> macro {
              id: capsule.Tools.getIdentifier(${m.id}),
              dependencies: capsule.Tools.getDependencies(${m.concrete})
            })}
          ];
          public static final __imports:Array<String> = [
            $a{imports.map(m ->  macro @:pos(m.pos) capsule.Tools.getIdentifier(${m}))}
          ];
        }).fields);
      default:
    }

    return fields;
  }
}
