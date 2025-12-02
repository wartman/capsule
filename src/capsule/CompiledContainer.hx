package capsule;

@:genericBuild(capsule.CompiledContainerBuilder.buildGeneric())
interface CompiledContainer<@:const Provides> {}

abstract class CompiledContainerBase {
	final container:capsule.Container;

	public function new(container) {
		this.container = container;
	}

	macro public function open(handler);
}
