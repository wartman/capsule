package fixture;

class Value implements ValueService {
  final value:String;

  public function new(value) {
    this.value = value;
  }

  public function get() {
    return value;
  }
}