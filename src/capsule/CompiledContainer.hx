package capsule;

abstract class CompiledContainer {
	final container:capsule.Container;

	public function new(container) {
		this.container = container;
	}

	macro public function open(handler);

	macro public function get(id);
}
