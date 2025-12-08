package coffeemaker;

import coffeemaker.CoffeeLogger;

class NullCoffeeLogger implements CoffeeLogger {
	public function new() {}

	public function log(message:String) {
		// noop
	}
}
