package capsule;

import capsule.provider.*;

class When<T> {
	final binding:Binding<T>;

	public function new(binding) {
		this.binding = binding;
	}

	public macro function resolved(expr);

	public macro function needs(expr);

	function applyTransform(transform:(value:T, bindings:BindingCollection) -> T) {
		var previous = binding.provider;
		binding.provider = new TransformerProvider(previous, transform);
		return this;
	}
}
