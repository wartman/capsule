package capsule.provider;

class TransformerProvider<T> implements Provider<T> {
	final provider:Provider<T>;
	final transform:(value:T, container:BindingCollection) -> T;
	var value:Null<T> = null;

	public function new(provider, transform:(value:T, bindings:BindingCollection) -> T) {
		this.provider = provider;
		this.transform = transform;
	}

	public function resolvable():Bool {
		return provider.resolvable();
	}

	public function resolve(bindings:BindingCollection):T {
		var shared = provider.isShared();

		if (shared && value != null) return value;

		var transformedValue = transform(this.provider.resolve(bindings), bindings);

		if (shared) value = transformedValue;

		return transformedValue;
	}

	public function transitionTo(other:Provider<T>):Provider<T> {
		return new TransformerProvider(provider.transitionTo(other), transform);
	}

	public function isShared() {
		return provider.isShared();
	}

	public function asShared():Provider<T> {
		return new TransformerProvider(provider.asShared(), transform);
	}

	public function clone():Provider<T> {
		return new TransformerProvider(provider.clone(), transform);
	}
}
