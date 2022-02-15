import capsule.Container;
import coffeemaker.CoffeeMaker;
import coffeemaker.CoffeeLoggerModule;
import coffeemaker.CoffeeMakerModule;
import coffeemaker.HeaterModule;
import coffeemaker.PumpModule;
import coffeemaker.CoffeeKernel;
import generics.ValueModule;
import generics.Value;

function main() {
  var container = Container.build(
    new CoffeeLoggerModule(),
    new CoffeeKernel(),
    new CoffeeMakerModule()
  );
  var coffeemaker = container.get(CoffeeMaker);
  coffeemaker.brew();

  var genericContainer = Container.build(new ValueModule());
  trace(genericContainer.get(Value(Int)).getValue() == 1);
  trace(genericContainer.get(Value(String)).getValue() == 'foo');
}
