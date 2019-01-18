package fixture.params;

class BaseParams<T, M> {

  public var foo:T;
  public var bar:M;

  public function new(foo:T, bar:M) {
    this.foo = foo;
    this.bar = bar;
  }

}
