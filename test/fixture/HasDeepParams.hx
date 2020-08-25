package fixture;

import haxe.ds.Map;

class HasDeepParams<T, M> {
  public var map:Map<T, M>;
  public var foo:T;

  public function new(foo:T, map:Map<T, M>) {
    this.map = map;
    this.foo = foo;
  }
}
