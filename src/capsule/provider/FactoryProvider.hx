package capsule.provider;

import capsule.exception.ProviderAlreadyExistsException;

class FactoryProvider<T> implements Provider<T> {
  var factory:(container:Container)->T;

  public function new(factory) {
    this.factory = factory;
  } 
  
  public function resolve(container:Container):T {
    return this.factory(container);
  }
  
  public function extend(transform:(value:T)->T) {
    var prev = factory;
    factory = container -> transform(prev(container));
  }

  public function asShared():Provider<T> {
    return new SharedProvider(this);
  }
  
  public function transitionTo(other:Provider<T>):Provider<T> {
    throw new ProviderAlreadyExistsException();
  }
}
