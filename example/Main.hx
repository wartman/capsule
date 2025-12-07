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

	var container = Container.compile(new ValueModule());

	container.open((int:Value<Int>, str:Value<String>, thing:String) -> {
		trace(int.getValue());
		trace(str.getValue());
		trace(thing);
	});

	// `container.get` is also checked at compile time:
	container.get(Value(Int)).getValue();
	container.get(Value(String)).getValue();
}
