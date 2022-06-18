package coffeemaker;

import capsule.Container;
import capsule.Module;

class HeaterModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(Heater).to(ElectricHeater).share();
  }
}
