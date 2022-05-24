package capsule.provider;

import capsule.exception.ProviderAlreadyExistsException;

class ValueProvider<T> implements Provider<T> {
  var value:T;
  
  public function new(value) {
    this.value = value;
  }
  
  public function resolvable() {
    return true;
  }

  public function resolve(container:Container):T {
    return value;
  }
  
  public function extend(transform:(value:T)->T) {
    value = transform(value);
  }

  public function asShared():Provider<T> {
    return this;
  }
  
  public function transitionTo(other:Provider<T>):Provider<T> {
    throw new ProviderAlreadyExistsException();
  }
}
