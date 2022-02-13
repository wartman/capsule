> Note:
>
> This branch is working on Capsule 2, a simplified version of Capsule that will
> (hopefully) add some compile-time checks for dependencies. Right now
> the new code can be found in `src/capsule2`.

Capsule 2
=========

[![Build Status](https://travis-ci.com/wartman/capsule.svg?branch=master)](https://travis-ci.com/wartman/capsule)


Capsule is a minimal, easy to use dependency-injection/IoC library.

Getting Started
---------------

Capsule's API is intentionally simple, and the majority of the complicated stuff it does happens during compile time.

To get started, lets do things the "wrong" way first and just create a container and map some types. There's a better way to do this, but that will make more sense once we've covered the basics.

We can map anything into our container, so lets just add a String and an Int:

```haxe
import capsule2.Container;

function main() {
  var container = new capsule2.Container();

  container.map(String).to('Foo');
  container.map(Int).to(1);
}
```

To get a value from our container, we just use `get`:

```haxe
container.get(String); // => "Foo"
```

This isn't particularly exciting or useful, so lets add something else -- a class with some dependencies in its constructor.

```haxe
class Foo {
  final foo:String;
  final bar:Int;

  public function new(foo, bar) {
    this.foo = foo;
    this.bar = bar;
  }

  public function getFooBar() {
    return foo + bar;
  }
}
```

The `map` method on our `container` returns a `capsule2.Mapping`, and the `to` method is actually a macro that does some (somewhat) fancy stuff to figure out what sort of mapping we want. In our current example we just passed a String and an Int, which are both constants, so they were mapped as values. If we map to `Foo` -- a class -- capsule will automatically figure out its dependencies from its constructor and inject them into a new instance when we call `get(Foo)`.

```haxe
import capsule2.Container;

function main() {
  var container = new capsule2.Container();

  container.map(String).to('Foo');
  container.map(Int).to(1);
  container.map(Foo).to(Foo);

  container.get(Foo).getFooBar(); // -> "Foo1"
}
```

We could make this better -- we really shouldn't be mapping `Foo` to itself. Instead, we should use an interface.

```haxe
interface FooService {
  public function getFooBar():String;
}

class Foo implements FooService {
  // ...
}
```

...and in our main file:

```haxe
import capsule2.Container;

function main() {
  var container = new capsule2.Container();

  container.map(String).to('Foo');
  container.map(Int).to(1);
  container.map(FooService).to(Foo);

  container.get(FooService).getFooBar(); // -> "Foo1"
}
```

We also really shouldn't be mapping `String` and `Int` directly, so lets make a `ValueService`.

```haxe
interface ValueService<T> {
  public function getValue():T;
}

class Value<T> implements ValueService<T> {
  final value:T;

  public function new(value) {
    this.value = value;
  }

  public function getValue() {
    return value;
  }
}
```

...and change our Foo class to use them:

```haxe
interface FooService {
  public function getFooBar():String;
}

class Foo implements FooService {
  final foo:ValueService<String>;
  final bar:ValueService<Int>;

  public function new(foo, bar) {
    this.foo = foo;
    this.bar = bar;
  }

  public function getFooBar() {
    return foo.getValue() + bar.getValue();
  }
}
```

Haxe doesn't let us use angle brackets for type parameters outside of a few specific places, making mapping generic types difficult. To get around this, Capsule abuses the function-call syntax:

```haxe
import capsule2.Container;

function main() {
  var container = new capsule2.Container();

  container.map(ValueService(String)).to(new Value('Foo'));
  container.map(ValueService(Int)).to(new Value(1));
  container.map(FooService).to(Foo);

  container.get(FooService).getFooBar(); // -> "Foo1"
}
```

An important note: the way our container is set up now, our `ValueServices` will always return the same type (as they're mapped to an instance), and our `FooService` will return a new instance every time.

Lets change that:

```haxe
import capsule2.Container;

function main() {
  var container = new capsule2.Container();

  // Mapping to a function will allow us to create a new instance every time
  container.map(ValueService(String)).to(() -> new Value('Foo'));

  // We can also use the same hacky call syntax to map to `Value<Int>`'s constructor:
  container.map(Int).to(1);
  container.map(ValueService(Int)).to(Value(Int));

  // `share` will cause the mapping to create a singleton
  container.map(FooService).to(Foo).share();

  container.get(FooService).getFooBar(); // -> "Foo1"
}
```

Just as a note, functions passed to `to` will automatically have their params injected. So, for example, you could do this:

```haxe
container.map(String).to(function (foo:ValueService<String>, bar:ValueService<Int>) {
  return foo.getValue() + bar.getValue();
});

// or:
function stringProvider(foo:ValueService<String>, bar:ValueService<Int>):String {
  return foo.getValue() + bar.getValue();
}
container.map(String).to(stringProvider);
```

You can also use `container.build` to immediately instantiate a type or call a function:

```haxe
var foo = container.build(Foo).getValue(); // -> "Foo1"
var fooBar = container.build(stringProvider); // -> "Foo1"
```

Modules
-------

> Note: Modules are working, but this feature is still early in development.

Right now we have a problem -- our container is very brittle. If we forget to map a dependency, we won't know about it until we get an exception during runtime. This is bad, and removes a lot of the benefit of using an IoC container.

Luckily, Capsule can track dependencies and warn us if we've forgotten anything. First, we'll need to use `capsule2.Modules`. Let's make two -- one for our ValueServices and one for our FooService.

> Note: It sure would be nice if I had a more real-world example here! I'll work on replacing this readme with that in the future. For now, bear with me.

```haxe
import capsule2.Module;
import capsule2.Container;

class ValueModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.map(ValueService(String)).to(new Value('Foo'));
    container.map(ValueService(Int)).to(new Value(1));
  }
}
```

```haxe
import capsule2.Module;
import capsule2.Container;

class FooModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.map(FooService).to(Foo).share();
  }
}
```

Let's change our main file, writing it in a way that won't compile first:

```haxe
import capsule2.Container;

function main() {
  var container = Container.create(new FooModule());
  container.get(FooService).getFooBar(); // -> "Foo1"
}
```

This should warn us that there are two unsatisfied dependencies: `ValueService<String>` and `ValueService<Int>`. If we add our `ValueModule`:

```haxe
import capsule2.Container;

function main() {
  var container = Container.create(new ValueModule(), new FooModule());
  container.get(FooService).getFooBar(); // -> "Foo1"
}
```

...everything should work, and we can be sure that the compiler will warn us if any of our dependencies change later.

Note that this feature will ONLY work if you use `Container.create` and tracking only happens inside `Modules`. 
