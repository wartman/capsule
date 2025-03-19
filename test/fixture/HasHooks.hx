package fixture;

import capsule.*;

class HasHooks implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.when(String).resolved((val:ValueService) -> value + '_' + val.get());
	}
}
