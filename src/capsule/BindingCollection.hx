package capsule;

using Lambda;

@:allow(capsule)
class BindingCollection {
	final bindings:Array<Binding<Dynamic>> = [];
	final parent:Null<BindingCollection>;

	public function new(?parent:BindingCollection) {
		this.parent = parent;
	}

	public function get<T>(id:Identifier #if debug, ?pos:haxe.PosInfos #end):Binding<T> {
		var binding:Null<Binding<T>> = cast bindings.find(binding -> binding.id == id);
		if (binding == null) {
			if (parent != null) return parent.get(id);
			return add(new Binding(id));
		}
		return binding;
	}

	public function resolve<T>(id:Identifier, #if debug ?pos:haxe.PosInfos #end):T {
		return get(id).provider.resolve(this);
	}

	@:noCompletion
	public function overrideParent<T>(id:Identifier):Binding<T> {
		var binding:Null<Binding<T>> = cast bindings.find(binding -> binding.id == id);
		if (binding == null) {
			return add(new Binding(id));
		}
		return binding;
	}

	public function child() {
		return new BindingCollection(this);
	}

	public function iterator():Iterator<Binding<Dynamic>> {
		return bindings.iterator();
	}

	function add<T>(binding:Binding<T>):Binding<T> {
		bindings.push(binding);
		return binding;
	}
}
