package fixture;

import haxe.ds.Map;

class HasDeepParams<T, M> {

  public var map:Map<T, M>;

  public function new(map:Map<T, M>) {
    this.map = map;
  }

}