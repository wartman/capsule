package capsule.provider;

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
}
