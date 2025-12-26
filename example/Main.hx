import capsule.Container;
import coffeemaker.*;
import robot.*;
import robot.standard.*;
import robot.friendly.*;

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
		new FriendlyRobotModule()
	).open((robot:Robot, friend:FriendlyRobot) -> {
		trace(robot.head.lookAt('tree'));
		trace(friend.head.lookAt('tree'));
	});
}
