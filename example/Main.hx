import capsule.Container;
import robot.*;
import robot.friendly.*;
import robot.generic.*;
import robot.standard.*;
import robot.logger.*;

function main() {
	Container.compile(
		new StandardRobotModule(),
		new FriendlyRobotModule(),
		new GenericRobotModule(),
		new DefaultLoggerModule()
	).open((logger:Logger, robot:Robot, friend:FriendlyRobot, standard:GenericRobot<Brain>, alsoFriend:GenericRobot<FriendlyBrain>) -> {
		logger.log(robot.head.lookAt('tree'));
		logger.log(friend.head.lookAt('tree'));
		logger.log(standard.head.lookAt('tree'));
		logger.log(alsoFriend.head.lookAt('tree'));
	});

	Container.compile(
		new StandardRobotModule(),
		new FriendlyRobotModule(),
		new GenericRobotModule(),
		new RobotsModule()
	).open((logger:Logger, robots:Array<Robot>) -> {
		for (robot in robots) logger.log(robot.head.lookAt('tree'));
	});
}
