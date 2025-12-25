package capsule.provider;

import capsule.exception.ProviderAlreadyExistsException;

class SharedProvider<T> implements Provider<T> {
	final provider:Provider<T>;
	var value:Null<T> = null;

	public function new(provider) {
		this.provider = provider;
	}

	public function resolvable() {
		return true;
	}

	public function resolve(bindings:BindingCollection):T {
		if (value == null) {
			value = provider.resolve(bindings);
		}
		return value;
	}

	public function transitionTo(other:Provider<T>):Provider<T> {
		throw new ProviderAlreadyExistsException();
	}

	public function isShared() {
		return true;
	}

	public function asShared():Provider<T> {
		return this;
	}

	public function clone() {
		return new SharedProvider(provider.clone());
	}
}
