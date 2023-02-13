package capsule.provider;

class OverridableProvider<T> implements Provider<T> {
	var provider:Provider<T>;
	final extensions:Array<(value:T) -> T> = [];

	public function new(provider) {
		this.provider = provider;
	}

	public function resolvable():Bool {
		return true;
	}

	public function resolve(container:Container):T {
		return provider.resolve(container);
	}

	public function extend(transform:(value:T) -> T) {
		extensions.push(transform);
		provider.extend(transform);
	}

	public function transitionTo(other:Provider<T>):Provider<T> {
		for (transform in extensions) other.extend(transform);
		return other;
	}

	public function asShared(options:ProviderSharingOptions):Provider<T> {
		provider = provider.asShared(options);
		return this;
	}

	public function asOverridable():Provider<T> {
		return provider.asOverridable();
	}
}
