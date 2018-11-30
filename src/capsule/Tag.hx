package capsule;

class Tag<@:const Name, T> {
  
  var getter:()->T;

  public function new(getter:()->T) {
    this.getter = getter;
  }

  public function get():T {
    return getter();
  }

}
