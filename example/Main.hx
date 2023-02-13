import capsule.Container;
import coffeemaker.*;
import generics.*;

function main() {
	var container = Container.build(new CoffeeLoggerModule(), new CoffeeKernel(), new CoffeeMakerModule());
	var coffeemaker = container.get(CoffeeMaker);
	coffeemaker.brew();

	var genericContainer = Container.build(new ValueModule());
	trace(genericContainer.get(Value(Int)).getValue() == 1);
	trace(genericContainer.get(Value(String)).getValue() == 'foo');
}
