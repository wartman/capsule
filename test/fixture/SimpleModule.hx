package fixture;

import capsule.Container;
import capsule.Module;

class SimpleModule implements Module {
  public function new() {}
  
  public function provide(container:Container) {
    container.bind(SimpleService).to(SimpleWithDep).share();
  }
}
