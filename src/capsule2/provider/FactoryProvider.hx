package capsule2.provider;

class FactoryProvider<T> implements Provider<T> {
  final factory:(container:Container)->T;

  public function new(factory) {
    this.factory = factory;
  } 
  
  public function resolve(container:Container):T {
    return this.factory(container);
  }
}
