package capsule2;

import capsule2.provider.SharedProvider;
import capsule2.provider.NullProvider;

class Mapping<T> {
  public final id:Identifier;
  final container:Container;
  var closure:Null<Container> = null;
  var provider:Provider<T> = new NullProvider();

  public function new(id, container) {
    this.id = id;
    this.container = container;
  }

  public function getContainer() {
    if (closure != null) return closure;
    return container;
  }

  public function with(cb:(container:Container)->Void) {
    if (closure == null) {
      closure = container.getChild();
    }
    cb(closure);
    return this;
  }

  public macro function to(ethis:haxe.macro.Expr, factory:haxe.macro.Expr) {
    var t = switch haxe.macro.Context.typeof(ethis) {
      case TInst(_, [ t ]): haxe.macro.TypeTools.toComplexType(t);
      default: macro:Dynamic;
    }
    var factory = capsule2.internal.FactoryBuilder.createFactory(factory, t, factory.pos);
    return macro @:pos(ethis.pos) $ethis.toProvider($factory);
  }

  public function toProvider(provider:Provider<T>):Mapping<T> {
    this.provider = provider;
    return this;
  }

  public function share():Mapping<T> {
    return toProvider(new SharedProvider(provider));
  }

  public function resolve():T {
    return provider.resolve(getContainer());
  }
}
