package capsule2;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using haxe.macro.Tools;
using capsule2.internal.Tools;

typedef TrackedMapping = {
  public var ?id:Expr;
  public var ?concrete:Expr;
}; 

class ModuleBuilder {
  public static function build() {
    var fields = Context.getBuildFields();
    var cls = Context.getLocalClass();
    var provider = fields.find(f -> f.name == 'provide');
    var containerName = 'container';
    var mappings:Array<TrackedMapping> = [];
    var currentMapping:Null<TrackedMapping> = null;

    // If `provide` doesn't exist yet, let Haxe complain.
    if (provider == null) return fields;
    
    function findMappings(e:Expr) {
      switch e.expr {
        case ECall(e, params): switch e.expr {
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
          mappings.push(currentMapping);
          currentMapping = null;
        default:
          e.iter(findMappings);
      }
    }

    switch provider.kind {
      case FFun(f):
        var expr = f.expr;
        containerName = f.args[0].name; // Ensure we have the right identifier.

        findMappings(expr);
        fields = fields.concat((macro class {
          public final __exports:Array<capsule2.Identifier> = [ 
            $a{mappings.map(m -> macro capsule2.Tools.getIdentifier(${m.id}))}
          ];
          public final __requires:Array<Array<capsule2.Identifier>> = [
            $a{mappings.map(m -> macro capsule2.Tools.getDependencies(${m.concrete}))}
          ];
        }).fields);
      default:
    }

    return fields;
  }
}
