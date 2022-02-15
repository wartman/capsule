package fixture;

import capsule.Container;
import capsule.Module;

class StringModule implements Module {
  final value:String;

  public function new(value) {
    this.value = value;
  }

  public function provide(container:Container) {
    container.map(String).to(value);
  }
}
