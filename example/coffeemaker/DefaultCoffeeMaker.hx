package coffeemaker;

class DefaultCoffeeMaker implements CoffeeMaker {
	final logger:CoffeeLogger;
	final heater:Heater;
	final pump:Pump;

	public function new(logger, heater, pump) {
		this.logger = logger;
		this.heater = heater;
		this.pump = pump;
	}

	public function brew() {
		heater.on();
		pump.pump();
		logger.log('Coffee!');
		heater.off();
	}
}
