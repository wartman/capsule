package capsule.provider;

import capsule.exception.ProviderAlreadyExistsException;

class ValueProvider<T> implements Provider<T> {
	var value:T;
	var options:ProviderSharingOptions;

	public function new(value, options) {
		this.value = value;
		this.options = options;
	}

	public function resolvable() {
		return true;
	}

	public function resolve(container:Container):T {
		return value;
	}

	public function extend(transform:(value:T) -> T) {
		value = transform(value);
	}

	public function transitionTo(other:Provider<T>):Provider<T> {
		throw new ProviderAlreadyExistsException();
	}

	public function asShared(options:ProviderSharingOptions):Provider<T> {
		this.options = options;
		return this;
	}

	public function asOverridable():Provider<T> {
		return switch options.scope {
			case Parent: new OverridableProvider(this);
			case Container: new OverridableProvider(new ValueProvider(value, options));
		}
	}
}
