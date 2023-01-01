package capsule.provider;

import capsule.exception.ProviderAlreadyExistsException;

class SharedProvider<T> implements Provider<T> {
  final provider:Provider<T>;
  var value:Null<T> = null;
  
  public function new(provider) {
    this.provider = provider;
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
      return;
    }
    provider.extend(transform);
  }
  
  public function asShared():Provider<T> {
    return this;
  }
  
  public function transitionTo(other:Provider<T>):Provider<T> {
    throw new ProviderAlreadyExistsException();
  }

  public function clone():Provider<T> {
    return new SharedProvider(provider.clone());
  }
}
