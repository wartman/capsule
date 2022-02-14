package generics;

class StringValue implements Value<String> {
  final value:String;

  public function new(value) {
    this.value = value;
  }

  public function getValue():String {
    return value;
  }
}
