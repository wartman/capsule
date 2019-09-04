package capsule;

@:allow(capsule.Container)
class Mapping<T> {
  
  final identifier:Identifier;
  var provider:Provider<T>;
  var closure:Container;

  public function new(identifier:Identifier, ?provider:Provider<T>) {
    this.identifier = identifier;
    this.provider = provider == null ? ProvideNone : provider;
  }

  public function with(cb:(closure:Container)->Void) {
    if (closure == null) closure = new Container();
    cb(closure);
    return this;
  }

  public macro function toClass(ethis:haxe.macro.Expr, cls:haxe.macro.Expr) {
    var mappingType = haxe.macro.Context.typeof(ethis);
    var factory = capsule.macro.ClassFactoryBuilder.create(cls, mappingType);
    return macro @:pos(ethis.pos) $ethis.toProvider(ProvideFactory(${factory}));
  }

  public macro function toFactory(ethis:haxe.macro.Expr, factory:haxe.macro.Expr) {
    var factory = capsule.macro.FunctionFactoryBuilder.create(factory);
    return macro @:pos(ethis.pos) $ethis.toProvider(ProvideFactory(${factory}));
  }

  public function toValue(value:T) {
    toProvider(ProvideValue(value));
    return this;
  }

  public function toProvider(provider:Provider<T>):Mapping<T> {
    checkProvider();
    this.provider = provider;
    return this;
  }

  public function asShared() {
    switch provider {
      case ProvideNone:
        throw new ProviderDoesNotExistError(identifier, 'You cannot share a mapping that does not have a provider.');
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
        resolve(container, factory);
      case ProvideShared(factory):
        var value = resolve(container, factory);
        provider = ProvideValue(value);
        value;
      case ProvideAlias(id): 
        handleLocalMappings(container).getValueByIdentifier(id);
    }
  }

  inline function resolve(container:Container, factory:(c:Container)->T) {
    return factory(handleLocalMappings(container));
  }

  function handleLocalMappings(container:Container):Container {
    if (closure != null) return closure.extend(container);
    return container;
  }

  public function extend(ext:(v:T)->T) {
    switch provider {
      case ProvideNone:
        throw new ProviderDoesNotExistError(identifier, 'You cannot extend a mapping that does not have a provider');
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
      throw new ProviderAlreadyExistsError(identifier);
    }
  }

}
