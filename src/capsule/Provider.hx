package capsule;

interface Provider<T> {
  public function resolve(container:Container):T;
  public function extend(transform:(value:T)->T):Void;
  public function asShared():Provider<T>;
  public function transitionTo(other:Provider<T>):Provider<T>;
}
