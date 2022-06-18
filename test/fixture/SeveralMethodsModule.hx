package fixture;

import capsule.Container;
import capsule.Module;

class SeveralMethodsModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    provideString(container);
    this.provideSimpleService(container);
    thisWillNotBeTracked();
    container.use(ValueModule);
  }

  function provideString(container:Container) {
    container.bind(String).to('foo');
  }

  function provideSimpleService(c:Container) {
    c.bind(SimpleService).to(SimpleWithDep).share();
  }

  function thisWillNotBeTracked() {
    // noop
  }
}

