package coffeemaker;

class ElectricHeater implements Heater {
	final logger:CoffeeLogger;
	var isHeating:Bool = false;

	public function new(logger) {
		this.logger = logger;
	}

	public function on() {
		isHeating = true;
		logger.log('~ heating ~');
	}

	public function off() {
		isHeating = false;
	}

	public function isHot():Bool {
		return isHeating;
	}
}
