import capsule.Container;
import coffeemaker.*;
import generics.*;

function main() {
	Container
		.compile(new CoffeeLoggerModule(), new CoffeeKernel(), new CoffeeMakerModule())
		.open((coffeemaker:CoffeeMaker, logger:CoffeeLogger) -> {
			coffeemaker.brew();
			logger.log('Done');
		});

	Container
		.compile(new ValueModule())
		.open((int:Value<Int>, str:Value<String>, thing:String) -> {
			trace(int.getValue());
			trace(str.getValue());
			trace(thing);
		});
}
