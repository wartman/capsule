package capsule.provider;

class TransformerProvider<T> implements Provider<T> {
	final provider:Provider<T>;
	final transform:(value:T, container:Container) -> T;

	public function new(provider, transform) {
		this.provider = provider;
		this.transform = transform;
	}

	public function resolvable():Bool {
		return provider.resolvable();
	}

	public function resolve(container:Container):T {
		return transform(this.provider.resolve(container), container);
	}

	public function transitionTo(other:Provider<T>):Provider<T> {
		return new TransformerProvider(provider.transitionTo(other), transform);
	}

	public function asShared():Provider<T> {
		return new TransformerProvider(provider.asShared(), transform);
	}

	public function clone():Provider<T> {
		return new TransformerProvider(provider.clone(), transform);
	}
}
