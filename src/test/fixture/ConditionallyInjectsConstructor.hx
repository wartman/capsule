package test.fixture;

class ConditionallyInjectsConstructor {

  public var foo:String;
  public var bar:String;
  public var bax:String;

  public function new(
    @:inject('foo') foo:String,
    @:noInject ?bax:String,
    @:inject('bar') bar:String
  ) {
    this.foo = foo;
    this.bar = bar;
    this.bax = bax == null ? 'default' : bax; 
  }

}
