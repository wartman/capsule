package capsule.provider;

import capsule.exception.ProviderAlreadyExistsException;

class SharedProvider<T> implements Provider<T> {
  final provider:Provider<T>;
  final options:ProviderSharingOptions;
  var value:Null<T> = null;
  
  public function new(provider, options) {
    this.provider = provider;
    this.options = options;
  }
  
  public function resolvable() {
    return true;
  }
  
  public function resolve(container:Container):T {
    if (value == null) {
      value = provider.resolve(container);
    }
    return value;
  }
  
  public function extend(transform:(value:T)->T) {
    if (value != null) {
      value = transform(value);
      switch options.scope {
        case Container: provider.extend(transform);
        default:
      }
      return;
    }
    provider.extend(transform);
  }

  public function transitionTo(other:Provider<T>):Provider<T> {
    throw new ProviderAlreadyExistsException();
  }
  
  public function asShared(options:ProviderSharingOptions):Provider<T> {
    if (options.scope == this.options.scope) return this;
    return new SharedProvider(provider, options);
  }

  public function asOverridable():Provider<T> {
    return switch options.scope {
      case Parent: new OverridableProvider(this);
      case Container: new OverridableProvider(new SharedProvider(provider, options));
    }
  }
}
