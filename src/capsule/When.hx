package capsule;

import capsule.provider.*;

class When<T> {
	final mapping:Mapping<T>;

	public function new(mapping) {
		this.mapping = mapping;
	}

	public macro function resolved(expr);

	function applyTransform(transform:(value:T, container:Container) -> T) {
		var previous = mapping.provider;
		mapping.provider = new TransformerProvider(previous, transform);
		return this;
	}
}
