package capsule2;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;

class ModuleBuilder {
  public static function build() {
    var fields = Context.getBuildFields();
    var cls = Context.getLocalClass();
    var provider = fields.find(f -> f.name == 'provide');

    // If `provide` doesn't exist yet, let Haxe complain.
    if (provider == null) return fields;

    

    return fields;
  }
}
