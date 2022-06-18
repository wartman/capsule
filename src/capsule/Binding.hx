package capsule;

import capsule.provider.NullProvider;

class Binding<T> {
  public final id:Identifier;
  final container:Container;
  var closure:Null<Container> = null;
  var provider:Provider<T>;

  public function new(id, container) {
    this.id = id;
    this.container = container;
    this.provider = new NullProvider(this.id);
  }

  public function getContainer() {
    if (closure != null) return closure;
    return container;
  }

  public function resolvable() {
    if (provider == null) return false;
    return provider.resolvable();
  }

  public function withContainer(container:Container) {
    var mapping = new Binding(id, container);
    mapping.toProvider(provider);
    return mapping;
  }

  public function with(cb:(container:Container)->Void) {
    if (closure == null) {
      closure = container.getChild();
    }
    cb(closure);
    return this;
  }

  public macro function to(self:haxe.macro.Expr, factory:haxe.macro.Expr) {
    var t = switch haxe.macro.Context.typeof(self) {
      case TInst(_, [ t ]): haxe.macro.TypeTools.toComplexType(t);
      default: macro:Dynamic;
    }
    var provider = capsule.internal.Builder.createProvider(factory, t, factory.pos);
    return macro @:pos(self.pos) $self.toProvider($provider);
  }

  public macro function toShared(self, factory) {
    return macro @:pos(self.pos) $self.to($factory).share();
  }

  public macro function toDefault(self, factory) {
    var t = switch haxe.macro.Context.typeof(self) {
      case TInst(_, [ t ]): haxe.macro.TypeTools.toComplexType(t);
      default: macro:Dynamic;
    }
    var provider = capsule.internal.Builder.createProvider(factory, t, factory.pos);
    return macro @:pos(self.pos) {
      var mapping = $self;
      if (!mapping.resolvable()) {
        mapping.toProvider(new capsule.provider.DefaultProvider($provider));
      }
      mapping;
    }
  }

  public function extend(transform:(value:T)->T) {
    provider.extend(transform);
    return this;
  }

  public function toProvider(provider:Provider<T>):Binding<T> {
    this.provider = this.provider.transitionTo(provider);
    return this;
  }

  public function share():Binding<T> {
    this.provider = provider.asShared();
    return this;
  }

  public function resolve():T {
    return provider.resolve(getContainer());
  }
}
