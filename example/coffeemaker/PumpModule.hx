package coffeemaker;

import capsule.Container;
import capsule.Module;

class PumpModule implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.map(Pump).to(Thermosiphon).share();
	}
}
