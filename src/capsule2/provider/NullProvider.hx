package capsule2.provider;

class NullProvider<T> implements Provider<T> {
  public function new() {}
  
  public function resolve(container:Container):T {
    throw 'No provider registered';
  }
}
