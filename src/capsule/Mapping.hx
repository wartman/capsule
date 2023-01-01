package capsule;

import capsule.provider.NullProvider;

class Mapping<T> {
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

  public function getChild(container:Container) {
    var mapping = new Mapping(id, container);
    mapping.toProvider(provider.asOverridable());
    return mapping;
  }

  public function with(cb:(container:Container)->Void) {
    if (closure == null) {
      closure = container.getChild();
    }
    cb(closure);
    return this;
  }

  public macro function to(factory);

  public macro function toShared(factory);

  public macro function toDefault(factory);

  public function extend(transform:(value:T)->T) {
    provider.extend(transform);
    return this;
  }

  public function toProvider(provider:Provider<T>):Mapping<T> {
    this.provider = this.provider.transitionTo(provider);
    return this;
  }

  public function share(?options:ProviderSharingOptions):Mapping<T> {
    if (options == null) options = ProviderSharingOptions.defaultSharingOptions;
    this.provider = provider.asShared(options);
    return this;
  }

  public function resolve():T {
    return provider.resolve(getContainer());
  }
}
