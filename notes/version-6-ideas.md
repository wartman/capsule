# Version 6

Version 6 will mainly focus on internal changes, and the APIs will be almost exactly the same.

## CompiledContainer

The one exception to this will be building the Container. Our plan is to make things much more type checked, meaning that the only way to interact with the Container (outside of an escape hatch we'll provide) will be by compiling it first.

```haxe
import capsule.*;

function main() {
  var container = Container.compile(
    new ValueModule(),
    new OtherValueModule(),
    new StartupModule()
  );
  // All arguments passed to `container.open` will be checked to make sure
  // they exist in the container's providers list at compile time.
  container.open((bootstrap:Bootstrap) -> {
    bootstrap.start();
  });
}
```

Or something.

The new class structure might look something like this:

```haxe
class Container {
  public macro static function compile(...modules);

  public macro function use(module);

	public macro function map(target);

	public macro function when(target);
}

interface CompiledContainer<Rest> {
  // This is the escape hatch:
  public final mappings:ContainerMappings;

  public macro function open(handler);
}

abstract ContainerMappings(Array<Mapping<Any>>) {
  public function get<T>(id:String):Mapping<T>;
}
```

## Internal stuff


