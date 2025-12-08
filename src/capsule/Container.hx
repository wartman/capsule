package capsule;

using Lambda;

class Container {
	public static macro function compile(...modules);

	final mappings:Array<Binding<Dynamic>> = [];

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
		for (mapping in mappings) {
			cloned.addBinding(mapping.clone());
		}
		return cloned;
	}

	@:noCompletion
	public function ensureBinding<T>(id:Identifier #if debug, ?pos:haxe.PosInfos #end):Binding<T> {
		var mapping:Null<Binding<T>> = cast mappings.find(mapping -> mapping.id == id);
		if (mapping == null) return addBinding(new Binding(id));
		return mapping;
	}

	@:noCompletion
	public function resolveBoundValue<T>(id:Identifier #if debug, ?pos:haxe.PosInfos #end):T {
		return ensureBinding(id).resolve(this);
	}

	function addBinding<T>(mapping:Binding<T>):Binding<T> {
		mappings.push(mapping);
		return mapping;
	}

	function useModule(module:Module) {
		module.provide(this);
		return this;
	}
}
