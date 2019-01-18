package fixture;

import capsule.ServiceProvider;
import capsule.Container;

class SimpleServiceProvider implements ServiceProvider {

  public function new() {}

  public function register(container:Container) {
    container.map(String, 'foo').toValue('foo');
  }

}
