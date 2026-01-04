import capsule.Container;
import coffeemaker.*;
import robot.*;
import robot.standard.*;
import robot.friendly.*;
import robot.generic.*;

function main() {
	Container.compile(
		new CoffeeLoggerModule(),
		new CoffeeApp()
	).open((coffeemaker:CoffeeMaker, logger:CoffeeLogger) -> {
		coffeemaker.brew();
		logger.log('Done');
	});

	Container.compile(
		new StandardRobotModule(),
		new FriendlyRobotModule(),
		new GenericRobotModule()
	).open((robot:Robot, friend:FriendlyRobot, standard:GenericRobot<Brain>, alsoFriend:GenericRobot<FriendlyBrain>) -> {
		trace(robot.head.lookAt('tree'));
		trace(friend.head.lookAt('tree'));
		trace(standard.head.lookAt('tree'));
		trace(alsoFriend.head.lookAt('tree'));
	});
}
