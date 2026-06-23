package robot.logger;

import capsule.*;

class DefaultLoggerModule implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.bind(Logger).to(DefaultLogger);
	}
}
