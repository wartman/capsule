package capsule;

class Tag<@:const Name, T> {
  
  var value:T;

  public function new(value:T) {
    this.value = value;
  }

  public function get():T {
    return value;
  }

}
