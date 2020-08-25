package fixture;

class HasTaggedParams<T> {
  public var foo:T;

  public function new(
    @:inject.tag('foo') foo:T
  ) {
    this.foo = foo;
  }
}
