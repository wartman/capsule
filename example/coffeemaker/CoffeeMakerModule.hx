package coffeemaker;

import capsule.Container;
import capsule.Module;

class CoffeeMakerModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(CoffeeMaker).to(DefaultCoffeeMaker);
  }
}
