package coffeemaker;

import capsule.Container;
import capsule.Module;

class CoffeeLoggerModule implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.map(CoffeeLogger).to(DefaultCoffeeLogger).share();
	}
}
