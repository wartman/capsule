package coffeemaker;

import capsule.Container;
import capsule.Module;

class CoffeeApp implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.bind(CoffeeLogger).toDefault(NullCoffeeLogger).share();

		container.use(HeaterModule, PumpModule, CoffeeMakerModule);
	}
}
