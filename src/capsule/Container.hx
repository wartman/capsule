package capsule;

using Lambda;

class Container {
	public static macro function build(...modules);

	final mappings:Array<Mapping<Dynamic>> = [];

	public function new() {}

	public macro function map(target);

	public macro function get(target);

	public macro function when(target);

	public macro function instantiate(target);

	public macro function use(...modules);

	public function clone() {
		var cloned = new Container();
		for (mapping in mappings) {
			cloned.addMapping(mapping.clone());
		}
		return cloned;
	}

	@:noCompletion
	public function ensureMapping<T>(id:Identifier #if debug, ?pos:haxe.PosInfos #end):Mapping<T> {
		var mapping:Null<Mapping<T>> = cast mappings.find(mapping -> mapping.id == id);
		if (mapping == null) return addMapping(new Mapping(id));
		return mapping;
	}

	@:noCompletion
	public function resolveMappedValue<T>(id:Identifier #if debug, ?pos:haxe.PosInfos #end):T {
		return ensureMapping(id).resolve(this);
	}

	function addMapping<T>(mapping:Mapping<T>):Mapping<T> {
		mappings.push(mapping);
		return mapping;
	}

	function useModule(module:Module) {
		module.provide(this);
		return this;
	}
}
