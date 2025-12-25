package capsule.provider;

class WhenNeedsBindingProvider<T, V> implements Provider<T> {
	final provider:Provider<T>;
	final id:Identifier;
	final factory:(bindings:BindingCollection) -> V;
	var value:Null<T> = null;

	public function new(provider, id, factory) {
		this.provider = provider;
		this.id = id;
		this.factory = factory;
	}

	public function resolvable():Bool {
		return provider.resolvable();
	}

	public function resolve(bindings:BindingCollection):T {
		var shared = provider.isShared();

		if (shared && value != null) return value;

		var localBindings = bindings.child();
		localBindings.overrideParent(id).toProvider(new ValueProvider(factory(bindings)));

		var value = provider.resolve(localBindings);

		if (shared) this.value = value;

		return value;
	}

	public function transitionTo(other:Provider<T>):Provider<T> {
		return new WhenNeedsBindingProvider(provider.transitionTo(other), id, factory);
	}

	public function isShared() {
		return provider.isShared();
	}

	public function asShared():Provider<T> {
		return new WhenNeedsBindingProvider(provider.asShared(), id, factory);
	}

	public function clone():Provider<T> {
		return new WhenNeedsBindingProvider(provider.clone(), id, factory);
	}
}
