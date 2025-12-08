package fixture;

import capsule.Container;

class SubClassedModule extends SimpleModule {
	override function provide(container:Container) {
		super.provide(container);
		container.bind(String).to('foo');
		container.bind(ValueService).to(Value);
	}
}
