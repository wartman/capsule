# Version 5

Version 5 will mainly focus on internal changes, and the APIs will be almost exactly the same.

The one exception to this will be building the Container. Our plan is to make things much more type checked, meaning that the only way to interact with the Container will be by compiling it first.

```haxe
import capsule.*;

function main() {
  var container = Container.compile(
    new ValueModule(),
    new OtherValueModule(),
    new StartupModule()
  );
  // All arguments passed to `container.use` will be checked to make sure
  // they exist in the container's providers list at compile time.
  container.use((bootstrap:Bootstrap) -> {
    bootstrap.start();
  });
}
````

Or something.
