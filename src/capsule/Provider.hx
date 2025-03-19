package capsule;

interface Provider<T> {
	public function resolvable():Bool;
	public function resolve(container:Container):T;
	public function transitionTo(other:Provider<T>):Provider<T>;
	public function asShared():Provider<T>;
	public function isShared():Bool;
	public function clone():Provider<T>;
}
