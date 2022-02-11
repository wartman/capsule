Capsule 2
=========

Capsule 2 will have some big changes, and will introduce an architecture similar to Angular.

The first big thing is that we will remove all injection metadata -- only constructor injection and function factories will be allowed. This is to encourage decoupling of all code from Capsule -- it should not be needed to run anything.

```haxe
interface BarService {
  public function getBar():String;
}

class Bar implements BarService {
  public function new () {}

  public function getBar():String {
    return 'bar';
  }
}

interface FooBarService {
  public function getFooBar():String;
}

class FooBar implements FooBarService {
  final bar:BarService;

  public function new(bar:BarService) {
    this.bar = bar;
  }

  public function getFooBar() {
    return 'foo${bar.getBar()}';
  }
}
```

The `capsule.Container` API will look pretty much exactly the same:

```haxe
var container = new capsule.Container();

container.map(BarService).to(Bar);
container.map(FooBarService).to(FooBar);

trace(container.get(FooBarService).getBar()); // => "foobar"
```

All other features -- support for generics, the way factory functions work, etc -- will all remain as well (although the use of generics might be discouraged and is probably not all that useful anyway).

The biggest feature that will be added are `Modules` -- a way to add a little static analysis to things and to enforce some good dev patterns (hopefully). A module looks like this:

```haxe
import capsule.Module;
import capsule.Container;
import capsule.Identifier;

class ExampleModule implements Module {
  public function register(container:Container) {
    container.map(FooBarService).to(FooBar);
  }
}
```

When a service is mapped to something in `register`, a macro will track its dependencies (assuming that turns out to be possible -- we may have to do some sort of DSL thing instead). Later, you'll use a ContainerBuilder in the root of your app:

```haxe
var builder = new ContainerBuilder();
builder.add(ExampleModule);
var container = builder.build();
```

When `build` is called a check will happen at compile time to ensure all dependencies are met. In this case they won't be -- `ExampleModule` doesn't provide a `BarService` for `FooBar`. To fix it, we could either provide a `BarService` in our ExampleModule:

```haxe
import capsule.Module;
import capsule.Container;
import capsule.Identifier;

class ExampleModule implements Module {
  public function register(container:Container) {
    container.map(BarService).to(Bar);
    container.map(FooBarService).to(FooBar);
  }
}
```

...or use another module:

```haxe
class OtherService implements Module {
  public function register(container:Container) {
    container.map(BarService).to(Bar);
  }
}
```

...and add it to our builder:

```haxe
var builder = new ContainerBuilder();
var container = builder
  .add(OtherService)
  .add(ExampleModule)
  .build();
```

Tags
====

We won't have tags -- instead, you'd just do this:

```haxe
typedef DbPassword = String;
typedef DbHost = String;
```

...and later:

```haxe
capsule.map(DbPassword).to('password');
capsule.map(DbHost).to('localhost:8080');
capsule.map(DbConnection).to(function (host:DbHost, password:DbPassword) {
  return new DbConnection(host, password);
});
```

I'm tempted to also drop support for generics entirely and force the use of typedefs if the user really wants them, but we'll see.
