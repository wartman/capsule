package fixture;

import capsule.Container;
import capsule.Module;

class ValueModule implements Module {
  final value:String;

  public function new(value) {
    this.value = value;
  }

  public function provide(container:Container) {
    container.map(ValueService).to(new Value(value));
  }
}
