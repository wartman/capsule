package coffeemaker;

import capsule.Container;
import capsule.Module;

/**
  This is just an example of how you can compose modules
  via `container.use`.
**/
class CoffeeKernel implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.use(HeaterModule, PumpModule);
  }
}
