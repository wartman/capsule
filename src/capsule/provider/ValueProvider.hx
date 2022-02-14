package capsule.provider;

class ValueProvider<T> implements Provider<T> {
  var value:T;
  
  public function new(value) {
    this.value = value;
  }
  
  public function resolve(container:Container):T {
    return value;
  }
  
  public function extend(transform:(value:T)->T) {
    value = transform(value);
  }
}
