package fixture;

import capsule.Container;
import capsule.Module;

class ParamModule implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.map(HasParamsService(ValueService)).to(HasParams(ValueService));
	}
}
