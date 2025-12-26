package capsule;

import capsule.provider.*;

class Needs<T, V> {
	final binding:Binding<T>;

	public function new(binding) {
		this.binding = binding;
	}

	public macro function give(expr);

	function applyNeedsBinding<V>(id:Identifier, factory:(bindings:BindingCollection) -> V) {
		var previous = binding.provider;
		binding.provider = new WhenNeedsBindingProvider(previous, id, factory);
		return this;
	}
}
