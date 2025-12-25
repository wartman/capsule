package capsule;

import capsule.provider.NullProvider;

@:allow(capsule)
class Binding<T> {
	public final id:Identifier;

	var provider:Provider<T>;

	public function new(id) {
		this.id = id;
		this.provider = new NullProvider(this.id);
	}

	public function resolvable() {
		return provider.resolvable();
	}

	public macro function to(factory);

	public macro function toShared(factory);

	public macro function toDefault(factory);

	public function toProvider(provider:Provider<T>):Binding<T> {
		this.provider = this.provider.transitionTo(provider);
		return this;
	}

	public function share():Binding<T> {
		this.provider = provider.asShared();
		return this;
	}

	public inline function resolve(container:Container):T {
		return provider.resolve(@:privateAccess container.bindings);
	}

	public function clone() {
		return new Binding(id).toProvider(provider.clone());
	}
}
