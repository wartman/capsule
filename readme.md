Capsule
=======

[![Build Status](https://travis-ci.com/wartman/capsule.svg?branch=master)](https://travis-ci.com/wartman/capsule)


Capsule is a minimal, easy to use dependency injection library.

Features
--------

- Simple, opinionated API. Capsule makes it easier to manage dependencies, but you should be able to use the same code without it. 
- All the complicated stuff is handled by macros -- at runtime Capsule is just a few simple classes.
- Using `capsule.Module`s and `capsule.Container.build` will check your dependencies at compile time -- no more runtime exceptions if you forget a class, and you'll be warned if any changes to your code requires a new dependency to be added.
  > Note: This feature is still a bit fragile and experimental.

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

interface FooService {
  public function getFoo():String;
}

interface BarService {
  public function getBar():String;
}

interface FooBarService {
  public function getFooBar():String;
}

class Foo implements FooService {
  public function new() {}

  public function getFoo() {
    return 'foo';
  }
}

class Bar implements BarService {
  public function new() {}

  public function getBar() {
    return 'bar';
  }
}

class FooBar implements FooBarService {
  final foo:FooService;
  final bar:BarService;

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
    container.map(FooService).to(Foo);
    container.map(BarServce).to(Bar);
  }
}

class FooBarModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.map(FooBarService).to(FooBar);
  }
}

function main() {
  var container = Container.build(
    new FooAndBarModule(),
    new FooBarModule()
  );
  trace(container.get(FooBarService).getFooBar()); // => "foobar"
}
```

This should all be pretty straightforward, but there are some important things to call out.

The first is that `Container.build` is a macro that checks the `capsule.Module`s passed to it to make sure that all dependencies are satisfied. If, for example, we omitted the `FooAndBarModule` from the above example:

```haxe
function main() {
  var container = Container.build(
    // new FooAndBarModule(),
    new FooBarModule()
  );
  trace(container.get(FooBarService).getFooBar());
}
```

...our could **wouldn't compile**. Instead, we'd get an error telling us that the `FooService` and `BarService` dependencies were not satisfied. You don't _need_ to use Capsule with `Container.build` and `Module`s, but it's probably a good idea.

> Importantly, if you map dependencies outside a `Module.provide` method Capsule currently **cannot** track the dependency.

Something that the example doesn't cover is how to handle generic types. Haxe only lets us use the angle bracket syntax (e.g. `Map<String, String>`) in a few places, so Capsule hacks the function-call syntax to get around this:

```haxe
capsule.map(Map(String, String)).to([ 'foo' => 'bar', 'bin' => 'bax' ]);
```

If you're new to Haxe, please note that this is **NOT** standard syntax. It'll only work in `capsule.map(...)`, `capsule.get(...)` and `capsule.to(...)`.

Another thing not covered in the example are the different kinds of values you can map to. The simplest is mapping to a Class, which automatically injects its constructor:

```haxe
container.map(FooBarService).to(FooBar);
```

However, say we wanted to provide a different implementation of `FooService` _only_ for `FooBarService`. We could map to a function instead:

```haxe
container.map(FooBarService).to(function (bar:BarService) {
  return new FooBar(new SomeOtherFooService(), bar);
});
```

Function params will all be injected by the container and tracked by `Module`s, just like mapping to a class. Note that any function will work here, so something like this is fine:

```haxe
container.map(FooBarService).to(FooBar.createWithCustomeFooService);
```

You can also just map a type to a value, like we did with `Map<String, String>`.

```haxe
// This will work:
container.map(String).to('foo');
```

Unlike the other mappings, value mappings will **always** return the same value. Function and Class mappings will be called every time, returning a new instance/value. This isn't always what we want, so you can mark a mapping as shared with the `share` method:

```haxe
container.map(FooBarService).to(FooBar).share();
```

This will ensure that an instance is only created once, and is returned whenever it's requested thereafter. 
