package coffeemaker;

import capsule.Container;
import capsule.Module;

class PumpModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(Pump).to(Thermosiphon).share();
  }
}
