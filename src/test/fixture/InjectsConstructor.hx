package test.fixture;

class InjectsConstructor {

  public var one:Plain;

  @:inject
  public function new(one:Plain) {
    this.one = one;
  }

}