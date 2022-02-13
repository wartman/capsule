package fixture2;

import capsule2.Container;
import capsule2.Module;

class ValueModule implements Module {
  final value:String;

  public function new(value) {
    this.value = value;
  }

	public function provide(container:Container) {
    container.map(ValueService).to(new Value(value));
  }
}
