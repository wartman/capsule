package capsule;

import capsule.provider.NullProvider;

@:allow(capsule)
class Mapping<T> {
	public final id:Identifier;

	var provider:Provider<T>;

	public function new(id) {
		this.id = id;
		this.provider = new NullProvider(this.id);
	}

	public function resolvable() {
		if (provider == null) return false;
		return provider.resolvable();
	}

	public macro function to(factory);

	public macro function toShared(factory);

	public macro function toDefault(factory);

	public function toProvider(provider:Provider<T>):Mapping<T> {
		this.provider = this.provider.transitionTo(provider);
		return this;
	}

	public function share():Mapping<T> {
		this.provider = provider.asShared();
		return this;
	}

	public inline function resolve(container:Container):T {
		return provider.resolve(container);
	}

	public function clone() {
		return new Mapping(id).toProvider(provider.clone());
	}
}
