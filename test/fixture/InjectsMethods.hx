package fixture;

class InjectsMethods {
  public var foo:String;
  public var bar:String;
  public var bin:String;
  public var bax:String;
  public var plain:Plain;

  public function new() {}

  @:inject public function injectFoo(foo:String) {
    this.foo = foo;
  }

  @:inject public function injectBarAndBin(
    @:inject.tag('bar') bar:String,
    @:inject.tag('bin') bin:String
  ) {
    this.bar = bar;
    this.bin = bin;
  }

  public function thisWontBeInjected(bar:String)
    this.bar = bar;

  @:inject public function mixedInjection(
    plain:Plain,
    @:inject.tag('bax') bax:String
  ) {
    this.plain = plain;
    this.bax = bax;
  }
}
