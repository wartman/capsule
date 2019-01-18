package fixture;

class InjectsValues {

  @:inject('foo') public var foo:String;
  @:inject('bar') public var bar:String;

  public function new() {}

}
