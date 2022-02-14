import capsule.Container;
import coffeemaker.CoffeeMaker;
import coffeemaker.CoffeeLoggerModule;
import coffeemaker.CoffeeMakerModule;
import coffeemaker.HeaterModule;
import coffeemaker.PumpModule;
import generics.ValueModule;
import generics.Value;

function main() {
  // Container.build ensures that all our dependencies 
  // are met! Try commenting out PumpModule or Heater Module to 
  // get a compile-time error.
  var container = Container.build(
    new CoffeeLoggerModule(),
    new PumpModule(),
    new HeaterModule(),
    new CoffeeMakerModule()
  );
  var coffeemaker = container.get(CoffeeMaker);
  coffeemaker.brew();

  var genericContainer = Container.build(new ValueModule());
  trace(genericContainer.get(Value(Int)).getValue() == 1);
  trace(genericContainer.get(Value(String)).getValue() == 'foo');
}
