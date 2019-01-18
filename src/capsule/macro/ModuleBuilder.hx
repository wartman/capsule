#if macro
package capsule.macro;

import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;
using Lambda;

class ModuleBuilder {

  static final provider:String = ':provide';
  static final use:String = ':use';

  public static function build() {
    if (Context.getLocalClass().get().superClass != null) {
      Context.error(
        'Modules do not currently support inheritance.'
        + ' Instead, use `@:use` with other modules -- just like you would with service providers.', 
        Context.currentPos()
      );
    }
    return new ModuleBuilder(Context.getBuildFields()).export();
  }

  var fields:Array<Field>;

  public function new(fields:Array<Field>) {
    this.fields = fields;
  }

  public function export() {
    var registerBody:Array<Expr> = [];

    var constructor = fields.find(f -> f.name == 'new');
    fields = fields.filter(f -> f.name != 'new');

    if (constructor == null) constructor = (macro class {

      public function new() {}

    }).fields.find(f -> f.name == 'new');
    var constructorBody:Array<Expr> = [];

    for (f in fields) switch(f.kind) {
      case FFun(func):
        if (f.meta.exists(m -> m.name == provider)) {
          var meta = f.meta.find(m -> m.name == provider);
          var tag = macro null;
          if (meta.params.length > 0) tag = meta.params[0];
          var name = func.ret.toType().follow().toString();
          var method = f.name;
          registerBody.push(macro @:pos(f.pos) c.__map($v{name}, ${tag}).toFactory($i{method}));
        }
      case FVar(t, e):
        var propName = f.name;
        if (f.meta.exists(m -> m.name == provider)) {
          var meta = f.meta.find(m -> m.name == provider);
          var tag = macro null;
          if (meta.params.length > 0) tag = meta.params[0];
          var name = t.toType().follow().toString();
          if (e != null) {
            constructorBody.push(macro $i{propName} = ${e});
            f.kind = FVar(t, null);
          }
          registerBody.push(macro @:pos(f.pos) c.__map($v{name}, ${tag}).toValue($i{propName}));
        }
        if (f.meta.exists(m -> m.name == use)) {
          if (e != null) {
            constructorBody.push(macro $i{propName} = ${e});
            f.kind = FVar(t, null);
          } else {
            var path = asTypePath(t.toType().toString());
            constructorBody.push(macro $i{propName} = new $path());
          }
          registerBody.push(macro @:pos(f.pos) c.use($i{propName}));
        }
      default:
    }

    switch (constructor.kind) {
      case FFun(f): 
        constructorBody.unshift(f.expr);
        f.expr = macro $b{constructorBody};
      default:
        Context.error('How on earth is the constructor not a function, what did you do.', constructor.pos);
    }

    return fields.concat(( macro class {

      public function register(c:capsule.Container) {
        $b{registerBody}
      }

    } ).fields).concat([ constructor ]);
  }

  static function asTypePath(s:String, ?params):TypePath {
    var parts = s.split('.');
    var name = parts.pop(),
      sub = null;
    if (parts.length > 0 && parts[parts.length - 1].charCodeAt(0) < 0x5B) {
      sub = name;
      name = parts.pop();
      if(sub == name) sub = null;
    }
    return {
      name: name,
      pack: parts,
      params: params == null ? [] : params,
      sub: sub
    };
  }

}
#end
