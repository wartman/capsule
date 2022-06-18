package fixture;

import capsule.Container;
import capsule.Module;

class SimpleWithDefaultsModule implements Module {
  public function new() {}
  
  public function provide(container:Container) {
    provideDefaults(container);
    container.bind(SimpleService).to(SimpleWithDep).share();
  }

  function provideDefaults(container:Container) {
    container.bind(ValueService).toDefault(new Value('foo'));
  }
}
