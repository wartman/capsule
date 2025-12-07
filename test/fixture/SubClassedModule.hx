package fixture;

import capsule.Container;

class SubClassedModule extends SimpleModule {
	override function provide(container:Container) {
		super.provide(container);
		container.map(String).to('foo');
		container.map(ValueService).to(Value);
	}
}
