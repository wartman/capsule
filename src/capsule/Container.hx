package capsule;

using Lambda;

class Container {
	public static macro function compile(...modules);

	final bindings = new BindingCollection();

	public function new() {}

	@:deprecated('Use `bind` instead')
	public macro function map(target);

	public macro function bind(target);

	public macro function get(target);

	public macro function when(target);

	public macro function instantiate(target);

	public macro function use(...modules);

	public function clone() {
		var cloned = new Container();
		for (binding in bindings) {
			cloned.bindings.add(binding.clone());
		}
		return cloned;
	}

	function useModule(module:Module) {
		module.provide(this);
		return this;
	}
}
