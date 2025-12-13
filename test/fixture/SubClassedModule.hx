package fixture;

import capsule.Container;

class SubClassedModule extends TargetModule {
	override function provide(container:Container) {
		super.provide(container);
		container.bind(String).to('foo');
	}
}

class TargetModule extends SimpleModule {
	override function provide(container:Container) {
		super.provide(container);
		container.bind(ValueService).to(Value);
	}
}
