Capsule
=======

[![Build Status](https://travis-ci.com/wartman/capsule.svg?branch=master)](https://travis-ci.com/wartman/capsule)

Capsule is a minimal, easy to use dependency injection library.

> Note: The previous version can be found [here](https://github.com/wartman/capsule/releases/tag/v0.2.6).

Features
--------

- Simple, opinionated API.
- All the complicated stuff is handled by macros -- at runtime Capsule is just a few simple classes.
- Using `capsule.Module`s and `capsule.Container.build` will check your dependencies at compile time -- no more runtime exceptions if you forget to add something, and you'll be warned if any changes to your code requires a new dependency.

Getting Started
---------------

Install using [Lix](https://github.com/lix-pm):

`lix install gh:wartman/capsule`

Install using haxelib:

> Not available yet

Add `-lib capsule` to your hxml file and you're ready to go!

Guide
-----

> The [examples](./example) folder is a good place to see how Capsule works too!

Here's a quick look at the API in action:

```haxe
import capsule.Container;
import capsule.Module;

interface Foo {
  public function getFoo():String;
}

interface Bar {
  public function getBar():String;
}

interface FooBar {
  public function getFooBar():String;
}

class DefaultFoo implements Foo {
  public function new() {}

  public function getFoo() {
    return 'foo';
  }
}

class DefaultBar implements Bar {
  public function new() {}

  public function getBar() {
    return 'bar';
  }
}

class DefaultFooBar implements FooBar {
  final foo:Foo;
  final bar:Bar;

  public function new(foo, bar) {
    this.foo = foo;
    this.bar = bar;
  }

  public function getFooBar() {
    return '${foo.geFoo()}${bar.getBar()}';
  }
}

class FooAndBarModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(Foo).to(DefaultFoo);
    container.bind(Bar).to(DefaultBar);
  }
}

class FooBarModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.bind(FooBar).to(DefaultFooBar);
  }
}

function main() {
  var container = Container.build(
    new FooAndBarModule(),
    new FooBarModule()
  );
  trace(container.get(FooBar).getFooBar()); // => "foobar"
}
```

This should all be pretty straightforward, but there are some important things to call out.

The first is that `Container.build` is a macro that ensures the dependencies of all `capsule.Module`s passed to it are satisfied. If, for example, we omitted the `FooAndBarModule` from the above example:

```haxe
function main() {
  var container = Container.build(
    // new FooAndBarModule(),
    new FooBarModule()
  );
  trace(container.get(FooBar).getFooBar());
}
```

...our code **wouldn't compile**. Instead, we'd get an error telling us that the `Foo` and `Bar` dependencies were not satisfied. You don't _need_ to use Capsule with `Container.build` and `Module`s, but it's probably a good idea.

Something that the example doesn't cover is how to handle generic types. Haxe only lets us use the angle bracket syntax (e.g. `Map<String, String>`) in a few places, so Capsule hacks the function-call syntax to get around this:

```haxe
capsule.bind(Map(String, String)).to([ 'foo' => 'bar', 'bin' => 'bax' ]);
```

> If you're new to Haxe, please note that this is **NOT** standard syntax. It'll only work in `capsule.bind(...)`, `capsule.get(...)` and `capsule.bind(...).to(...)`.

Another thing not covered in the example are the different kinds of values you can bind. The simplest is binding a Class, which automatically injects its constructor:

```haxe
container.bind(FooBar).to(FooBar);
```

However, say we wanted to provide a different implementation of `Foo` _only_ for `FooBar`. We could bind a function instead:

```haxe
container.bind(FooBar).to(function (bar:Bar) {
  return new FooBar(new SomeOtherFoo(), bar);
});
```

Function parameters will all be injected by the container and tracked by `Module`s, just like binding a class. Note that any function will work here, so something like this is fine:

```haxe
container.bind(FooBar).to(FooBar.createWithCustomFoo);
```

> Internally Capsule is actually binding **everything** to functions -- `container.bind(FooBar).to(FooBar)` is the same as `container.bind(FooBar).to(FooBar.new)`, and if you poke around in the source code you'll see that's exactly what's happening.

You can also just bind a type to a value, like we did with `Map<String, String>`.

```haxe
// This will work:
container.bind(String).to('foo');
```

Unlike the other bindings, value bindings will **always** return the same value. Function and Class bindings will be called every time, returning a new instance/value. This isn't always what we want, so you can mark a binding as shared with the `share` method:

```haxe
container.bind(FooBar).to(DefaultFooBar).share();
```

Because this is such a common pattern, you can also use the `toShared` shortcut to do the same thing:

```haxe
container.bind(FooBar).toShared(DefaultFooBar);
```

This will ensure that an instance is only created once, and is returned whenever it's requested thereafter.

If you need to extend a binding -- say you need to register a route to a router in some notional web app -- you can call `getBinding` from your Container and `extend` it:

```haxe
conatiner.getBinding(Router).extend(router -> {
  router.add(new Route('/foo/bar'));
  // You MUST return a Router from this function. Note that this means
  // you're also able to change the value of a binding using `extend`.
  return router;
});
```

Importantly, you can `extend` a binding that **does not exist yet**. The following code will work just fine:

```haxe
conatiner.getBinding(Router).extend(router -> {
  router.add(new Route('/foo/bar'));
  // You MUST return a Router from this function. Note that this means
  // you're also able to change the value of a binding using `extend`.
  return router;
});
container.bind(Router).toShared(Router);
```

This is done to ensure that you don't need to worry about the order you bind things in -- everything should just work.

Changelog
---------

### 0.4.0
- Changed `Mapping` to `Binding`, `container.map` to `container.bind`, and any other reference to `map`. This was done entirely because `map` is generally used in Haxe to mean the same thing it does in functional programming -- that is, to map one value into another. That's pretty close to what it means in capsule, but `binding` is more explicit.

### 0.3.0
- Breaks anything that used the old version of Capsule. Is that a feature?
  - I promise it's for the best.
- Removed all `@:inject.*` meta. Instead, dependencies are only injected into constructors (or derived from any function's arguments). This is to simplify the API and ensure that code doesn't require Capsule to work.
- All functions passed to the `Binding.to(...)` macro are injectable now, not just lambdas.
- `capsule.Module` replaces `capsule.ServiceProvider` and tracks dependencies at compile time.
