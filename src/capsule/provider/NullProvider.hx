package capsule.provider;

import capsule.exception.ProviderDoesNotExistException;

class NullProvider<T> implements Provider<T> {
	final id:Identifier;

	public function new(id) {
		this.id = id;
	}

	public function resolvable() {
		return false;
	}

	public function resolve(container:Container):T {
		throw new ProviderDoesNotExistException(id);
	}

	public function transitionTo(other:Provider<T>):Provider<T> {
		return other;
	}

	public function asShared():Provider<T> {
		throw new ProviderDoesNotExistException(id, 'Cannot share a null provider');
	}

	public function clone() {
		return this;
	}
}
