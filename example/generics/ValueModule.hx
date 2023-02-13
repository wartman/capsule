package generics;

import capsule.Container;
import capsule.Module;

class ValueModule implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.map(String).to('foo');
		container.map(Value(Int)).to(new GenericValue(1));
		container.map(Value(String)).to(StringValue);
	}
}
