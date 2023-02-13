package fixture;

import capsule.Container;
import capsule.Module;

/**
	This shows how module compisition works. Note that `ValueModule`
	has a constructor that takes a String, so this module has one
	`String` dependency that must be met.
**/
class ComposedModule implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.use(ValueModule, ParamModule);
	}
}
