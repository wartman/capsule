package fixture;

class HasParams<T> implements HasParamsService<T> {
  final value:T;
  
  public function new(value:T) {
    this.value = value;
  }
  
  public function getValue():T {
    return value;
  }
}
