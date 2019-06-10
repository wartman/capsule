package capsule.refactor;

@:allow(capsule.refactor.Container)
class Mapping<T> {
  
  final identifier:Identifier;
  var provider:Provider<T>;

  public function new(identifier:Identifier, ?provider:Provider<T>) {
    this.identifier = identifier;
    this.provider = provider == null ? ProvideNone : provider;
  }

  public macro function toClass(ethis:haxe.macro.Expr, cls:haxe.macro.Expr) {
    var mappingType = haxe.macro.Context.typeof(ethis);
    var factory = capsule.refactor.macro.ClassFactoryBuilder.create(cls, mappingType);
    return macro @:pos(ethis.pos) $ethis.toFactory(${factory});
  }

  public function toFactory(factory:Factory<T>) {
    toProvider(ProvideFactory(factory));
    return this;
  }

  public function toValue(value:T) {
    toProvider(ProvideValue(value));
    return this;
  }

  public function toProvider(provider:Provider<T>) {
    checkProvider();
    this.provider = provider;
    return this;
  }

  public function asShared() {
    switch provider {
      case ProvideNone:
        throw 'You cannot share a mapping that does not have a provider';
      case ProvideAlias(id):
        provider = ProvideShared(c -> c.getValueByIdentifier(id));
      case ProvideFactory(factory):
        provider = ProvideShared(factory);
      case ProvideValue(_) | ProvideShared(_):
        // noop
    }
    return this;
  }

  public function getValue(container:Container):T {
    return switch provider {
      case ProvideNone: 
        null;
      case ProvideValue(value):
        value;
      case ProvideFactory(factory): 
        factory(container);
      case ProvideShared(factory):
        var value = factory(container);
        provider = ProvideValue(value);
        value;
      case ProvideAlias(id): 
        container.getValueByIdentifier(id);
    }
  }

  public function extend(ext:(v:T)->T) {
    switch provider {
      case ProvideNone:
        throw 'You cannot extend a mapping that does not have a provider';
      case ProvideValue(value):
        provider = ProvideValue(ext(value));
      case ProvideFactory(factory):
        provider = ProvideFactory(c -> ext(factory(c)));
      case ProvideShared(factory):
        provider = ProvideShared(c -> ext(factory(c)));
      case ProvideAlias(id): 
        provider = ProvideFactory(c -> ext(c.getValueByIdentifier(id)));
    }
    return this;
  }

  function checkProvider() {
    if (provider != ProvideNone) {
      throw 'A mapping was already bound to a provider';
    }
  }

}
