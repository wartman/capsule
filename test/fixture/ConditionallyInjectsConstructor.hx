package fixture;

class ConditionallyInjectsConstructor {
  public var foo:String;
  public var bar:String;
  public var bax:String;

  public function new(
    @:inject.tag('foo') foo:String,
    @:inject.skip ?bax:String,
    @:inject.tag('bar') bar:String
  ) {
    this.foo = foo;
    this.bar = bar;
    this.bax = bax == null ? 'default' : bax; 
  }
}
