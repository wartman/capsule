package robot.friendly;

import capsule.*;

class FriendlyRobotModule implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.bind(FriendlyRobot).to(Robot).share();
		container.when(FriendlyRobot).needs(Brain).give(FriendlyBrain);
	}
}
