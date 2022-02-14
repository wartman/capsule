package coffeemaker;

class Thermosiphon implements Pump {
  final logger:CoffeeLogger;
  final heater:Heater;
  
  public function new(logger, heater) {
    this.logger = logger;
    this.heater = heater;
  }
  
  public function pump() {
    if (heater.isHot()) {
      logger.log('=> pumping =>');
    }
  }
}
