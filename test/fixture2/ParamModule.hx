package fixture2;

import capsule2.Container;
import capsule2.Module;

class ParamModule implements Module {
  public function new() {}
  
  public function provide(container:Container) {
    container.map(HasParamsService(ValueService)).to(HasParams(ValueService));
  }
}
