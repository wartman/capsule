package robot;

import capsule.*;
import robot.logger.DefaultLoggerModule;

class RobotsModule implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.use(DefaultLoggerModule);
		container.bind(Array(Robot)).to([]);
	}
}
