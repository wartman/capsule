package fixture;

abstract AbstractString(String) {
  public function new(value:String) {
    this = value;
  }

  @:to public function unBox():String {
    return this;
  }
}
