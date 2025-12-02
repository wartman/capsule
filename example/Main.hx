import capsule.Container;
import coffeemaker.*;
import generics.*;

function main() {
	var container = Container.compile(new CoffeeLoggerModule(), new CoffeeKernel(), new CoffeeMakerModule());
	container.open((coffeemaker:CoffeeMaker) -> {
		coffeemaker.brew();
	});

	var genericContainer = Container.compile(new ValueModule());
	genericContainer.open((int:Value<Int>, str:Value<String>) -> {
		trace(int.getValue());
		trace(str.getValue());
	});
}
