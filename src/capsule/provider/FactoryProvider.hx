package capsule.provider;

import capsule.exception.ProviderAlreadyExistsException;

class FactoryProvider<T> implements Provider<T> {
	var factory:(bindings:BindingCollection) -> T;

	public function new(factory) {
		this.factory = factory;
	}

	public function resolvable() {
		return true;
	}

	public function resolve(bindings:BindingCollection):T {
		return this.factory(bindings);
	}

	public function transitionTo(other:Provider<T>):Provider<T> {
		throw new ProviderAlreadyExistsException();
	}

	public function isShared() {
		return false;
	}

	public function asShared():Provider<T> {
		return new SharedProvider(this);
	}

	public function clone() {
		return new FactoryProvider(factory);
	}
}
