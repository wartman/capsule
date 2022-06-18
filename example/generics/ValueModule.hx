package generics;

import capsule.Container;
import capsule.Module;

class ValueModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(String).to('foo');
    container.bind(Value(Int)).to(new GenericValue(1));
    container.bind(Value(String)).to(StringValue);
  }
}
