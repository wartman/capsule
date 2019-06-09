package capsule.refactor;

@:allow(capsule.refactor.Container)
class Mapping<T> {
  
  final identifier:Identifier;
  var provider:Provider<T>;

  public function new(identifier:Identifier, ?provider:Provider<T>) {
    this.identifier = identifier;
    this.provider = provider == null ? Provider.empty() : provider;
  }

  // public macro function toClass() {}

  public function toFactory(factory:Factory<T>) {
    toProvider(Provider.factory(factory));
    return this;
  }

  public function toValue(value:T) {
    toProvider(Provider.value(value));
    return this;
  }

  public function toProvider(provider:Provider<T>) {
    checkProvider();
    this.provider = provider;
    return this;
  }

  public function asShared() {
    switch provider.unbox() {
      case None:
        throw 'You cannot share a mapping that does not have a provider';
      case ProvideAlias(id):
        provider = Provider.shared(c -> c.getValueByIdentifier(id));
      case ProvideFactory(factory):
        provider = Provider.shared(factory);
      case ProvideValue(_) | ProvideShared(_):
        // noop
    }
    return this;
  }

  public function getValue(container:Container):T {
    return switch provider.unbox() {
      case None: 
        null;
      case ProvideValue(value):
        value;
      case ProvideFactory(factory): 
        factory(container);
      case ProvideShared(factory):
        var value = factory(container);
        provider = Provider.value(value);
        value;
      case ProvideAlias(id): 
        container.getValueByIdentifier(id);
    }
  }

  public function extend(ext:(v:T)->T) {
    switch provider.unbox() {
      case None:
        throw 'You cannot extend a mapping that does not have a provider';
      case ProvideValue(value):
        provider = Provider.value(ext(value));
      case ProvideFactory(factory):
        provider = Provider.factory(c -> ext(factory(c)));
      case ProvideShared(factory):
        provider = Provider.shared(c -> ext(factory(c)));
      case ProvideAlias(id): 
        provider = Provider.factory(c -> ext(c.getValueByIdentifier(id)));
    }
    return this;
  }

  function checkProvider() {
    if (provider.unbox() != None) {
      throw 'A mapping was already bound to a provider';
    }
  }

}
