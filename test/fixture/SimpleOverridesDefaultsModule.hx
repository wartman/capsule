package fixture;

import capsule.Container;
import capsule.Module;

class SimpleOverridesDefaultsModule implements Module {
  public function new() {}
  
  public function provide(container:Container) {
    container.map(ValueService).to(new Value('override'));
  }
}
