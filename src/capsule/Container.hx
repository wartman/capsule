package capsule;

using Lambda;

class Container {
	public static macro function compile(...modules);

	final bindings:Array<Binding<Dynamic>> = [];

	public function new() {}

	@:deprecated('Use `bind` instead')
	public macro function map(target);

	public macro function bind(target);

	public macro function get(target);

	public macro function when(target);

	public macro function instantiate(target);

	public macro function use(...modules);

	public function clone() {
		var cloned = new Container();
		for (binding in bindings) {
			cloned.addBinding(binding.clone());
		}
		return cloned;
	}

	@:noCompletion
	public function ensureBinding<T>(id:Identifier #if debug, ?pos:haxe.PosInfos #end):Binding<T> {
		var binding:Null<Binding<T>> = cast bindings.find(binding -> binding.id == id);
		if (binding == null) return addBinding(new Binding(id));
		return binding;
	}

	@:noCompletion
	public function resolveBoundValue<T>(id:Identifier #if debug, ?pos:haxe.PosInfos #end):T {
		return ensureBinding(id).resolve(this);
	}

	function addBinding<T>(binding:Binding<T>):Binding<T> {
		bindings.push(binding);
		return binding;
	}

	function useModule(module:Module) {
		module.provide(this);
		return this;
	}
}
