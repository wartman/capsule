package capsule.provider;

class OverridableProvider<T> implements Provider<T> {
	var provider:Provider<T>;

	public function new(provider) {
		this.provider = provider;
	}

	public function resolvable():Bool {
		return true;
	}

	public function resolve(container:Container):T {
		return provider.resolve(container);
	}

	public function transitionTo(other:Provider<T>):Provider<T> {
		return other;
	}

	public function asShared():Provider<T> {
		provider = provider.asShared();
		return this;
	}

	public function clone() {
		return new OverridableProvider(provider.clone());
	}
}
