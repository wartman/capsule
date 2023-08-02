package capsule;

import capsule.provider.NullProvider;

@:allow(capsule)
class Mapping<T> {
	public final id:Identifier;

	final container:Container;
	var provider:Provider<T>;

	public function new(id, container) {
		this.id = id;
		this.container = container;
		this.provider = new NullProvider(this.id);
	}

	public function resolvable() {
		if (provider == null) return false;
		return provider.resolvable();
	}

	public function clone() {
		var mapping = new Mapping(id, container);
		mapping.toProvider(provider.clone());
		return mapping;
	}

	public macro function to(factory);

	public macro function toShared(factory);

	public macro function toDefault(factory);

	public function extend(transform:(value:T) -> T) {
		provider.extend(transform);
		return this;
	}

	public function toProvider(provider:Provider<T>):Mapping<T> {
		this.provider = this.provider.transitionTo(provider);
		return this;
	}

	public function share():Mapping<T> {
		this.provider = provider.asShared();
		return this;
	}

	public function resolve():T {
		return provider.resolve(container);
	}
}
