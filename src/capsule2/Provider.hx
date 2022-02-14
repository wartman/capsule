package capsule2;

interface Provider<T> {
  public function resolve(container:Container):T;
  public function extend(transform:(value:T)->T):Void;
}
