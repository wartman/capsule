package robot.generic;

import robot.friendly.FriendlyBrain;
import capsule.*;

class GenericRobotModule implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.bind(FriendlyBrain).to(FriendlyBrain);
		container.bind(GenericRobot(Brain)).to(GenericRobot(Brain));
		container.bind(GenericRobot(FriendlyBrain)).to(GenericRobot(FriendlyBrain));
	}
}
