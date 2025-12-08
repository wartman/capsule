import capsule.Container;
import coffeemaker.*;

function main() {
	Container.compile(
		new CoffeeLoggerModule(),
		new CoffeeApp()
	).open((coffeemaker:CoffeeMaker, logger:CoffeeLogger) -> {
		coffeemaker.brew();
		logger.log('Done');
	});
}
