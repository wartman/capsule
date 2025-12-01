package fixture;

import capsule.*;

class HasHooks implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.when(String).resolved((str, val:ValueService) -> str + '_' + val.get());
	}
}
