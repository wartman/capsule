package capsule2.provider;

class ValueProvider<T> implements Provider<T> {
  final value:T;
  
  public function new(value) {
    this.value = value;
  }
  
  public function resolve(container:Container):T {
    return value;
  }
}
