package fixture2;

import capsule2.Container;
import capsule2.Module;

class SimpleModule implements Module {
  public function new() {}
  
  public function provide(container:Container) {
    container.map(SimpleService).to(SimpleWithDep).share();
  }
}
