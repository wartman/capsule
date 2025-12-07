# Capsule

Capsule is a minimal, easy to use dependency injection/IoC library that checks your dependencies at compile time.

## Features

- Simple API.
- All the complicated stuff is handled by macros -- at runtime Capsule is just a few simple classes.
- Using `capsule.Module`s and `capsule.Container.compile` will check your dependencies at compile time -- no more runtime exceptions if you forget to add something, and you'll be warned if any changes to your code requires a new dependency.

## Getting Started

Install using [Lix](https://github.com/lix-pm):

`lix install gh:wartman/capsule`

Install using haxelib:

> Not available yet

Add `-lib capsule` to your hxml file and you're ready to go!

## Guide

> Be sure to check the [examples](./example) folder for some working code. 

Capsule's API is very simple and should be familiar if you've ever used a dependency injection framework. It does have a few quirks due to its heavy use of macros and some of the limitations of Haxe's syntax, but we'll cover those when they come up.

Before we start, lets take a look at an example of the *recommended* way to create a Container. We'll then strip things back to a simpler example, go over the basics of how mapping dependencies to the Container works, and then bring back more advanced concepts and explain while they're needed.

```haxe
import capsule.*;

class Value<T> {
  final value:T;

  public function new(value) {
    this.value = value;
  }

  public function getValue() {
    return this.value;
  }
}

class StringModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.map(String).to('foo');
    container.map(Value(String)).to(Value(String)).share();

    container.when(Value(String)).resolved((value, str:String) -> {
      trace(value.getValue() == str);
      value;
    });
  }
}

function main() {
  Container
    .compile(new StringModule())
    .open((value:Value(String)) -> {
      trace(value.getValue());
    });
}
```

There's a lot going on here, so let's start by just looking at the Container.

### Container

While you *should* use the `Container.compile` macro (for reasons we'll get into shortly), for the purposes of this example we'll just create a container directly and map a value to it.

```haxe
var container = new Container();
container.map(String).to('foo');
```

Now that we've done this, we can ask our container for a `String` and we'll get `'foo'` back.

```haxe
container.get(String); // -> 'foo'
```

More importantly, we can now use this mapped value to satisfy the dependencies of other mappings in the container. Let's take the `Value<T>` class from the initial example. There are a few ways we could add it to our container, but lets start with a callback.

```haxe
container.map(Value(String)).to((str:String) -> new Value(str));
```

> Note: In an ideal world, we'd write this like `container.map(Value<String>).to(...)`, or perhaps `container.map<Value<String>>().to(...)`. Unfortunately Haxe does not allow this, so Capsule uses the function-call syntax for generics instead as a bit of a hack. This is not a normal Haxe thing -- Capsule is using macros here.

Now when we ask for a `Value<String>` it will create a new instance of the Value class, inject the `String` mapping and give us the result.

```haxe
var value = container.get(Value(String)); 
value.getValue(); // -> 'foo' 
```

To make this simpler, we could also map directly to the `Value<T>` class, which automatically injects its constructor.

```haxe
container.map(Value(String)).to(Value(String));
```

This means that we could, for example, add a new dependency to our `Value<T>` class. 

```haxe
interface Logger {
  public function log(message:String):Void;
}

class Value<T> {
  final value:T;
  final logger:Logger;

  public function new(value, logger) {
    this.value = value;
    this.logger = logger;
  }

  public function getValue() {
    logger.log('Getting value: ${this.value}');
    return this.value;
  }
}
```

If we were mapping `Value<String>` to our container using a callback, we'd have to go in and change things manually to make it work.

```haxe
container.map(Value(String)).to((str:String, logger:Logger) -> new Value(str, logger));
```

This is why it's recommended to map to a class whenever possible and allow Capsule to automatically inject dependencies.

> Note: Internally, `container.map(Value(String)).to(Value(String))` is the same as writing `container.map(Value(String)).to(Value.new)`. Capsule uses a macro to inspect the expression passed to the `to` method. If it's a value, like `"String"` or an instance like `new Value("Foo")`, it will map the type directly to that value. If it's a class or a function, it will inspect the arguments of the function (or constructor) and generate the code needed to resolve the dependencies from the Container.

However we still have a problem, regardless of which method we use. We don't have a `Logger` mapped to our container. When we try to get a `Value<String>` from it we'll get a *runtime* exception telling us that it's missing a dependency. This is something we can fix and it's better than nothing, but wouldn't it be better if our code warned us at compile time that a dependency was missing?

### Modules and CompiledContainers

This is where Modules come in. While they're also a useful way to organize dependencies, they also allow Capsule to build a dependency graph and warn you if you're missing (or repeating) a mapping.

This *only* works if you're using `Container.compile`. This is a macro that will build a `CompiledContainer` which contains a list of all the dependencies it can satisfy. It will also check the Modules its given, at compile time, to make sure that no dependency is missing.

Lets use our `Value<T>` class with its `Logger` dependency. As it stands, the following code will not compile and instead we'll get a warning similar to `the mapping Value<String> requires Logger`. 

```haxe
class ValueModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.map(String).to('foo');
    container.map(Value(String)).to(Value(String));
  }
}

function main() {
  var container = Container.compile(new ValueModule());
}
```

We *could* add a mapping for our `Logger` in the `ValueModule` module, but lets create a new module instead and use that.

```haxe
class SimpleLogger implements Logger {
  public function new() {}

  public function log(message:String) {
    trace(message);
  }
}

class SimpleLoggerModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    // Note that we're mapping an interface to an implementing class:
    container.map(Logger).to(SimpleLogger);
  }
}
```

Once we add this module our code will compile.

```haxe
function main() {
  var container = Container.compile(new SimpleLoggerModule(), new ValueModule());
}
```

To get at our mapped values, we can use `container.open(...)` or `container.get(...)`. Capsule will also check both of these methods at compile time and warn us if it can't satisfy the requested mapping.

```haxe
function main() {
  var container = Container.compile(new SimpleLoggerModule(), new ValueModule());

  // The following will work:
  container.open((value:Value<String>, logger:Logger) -> {
    logger.log('Hello world');
    var value = value.getValue();
  });
  var value = container.get(Value(String));
  
  // ...but if we ask for something the CompiledContainer does not have (such as 
  // Value<Int>) we'll get an error:
  container.open((value:Value<Int>, logger:Logger) -> {
    logger.log('Hello world');
    var value = value.getValue();
  });
  var value = container.get(Value(Int));
}
```

### Advanced Mapping

There are still a few issues with our code. The most important one is that a new `Logger` will be created *every time* it's requested, which we don't want. Fixing this is simple: we need to mark it as `shared`. There are two ways to do this:

```haxe
// Using the `share` method:
container.map(Logger).to(SimpleLogger).share();

// Using the `toShared` shortcut:
container.map(Logger).toShared(SimpleLogger);
```

This means that the Logger will *only be created once*, the first time it's requested.

We might also want to make the Logger overridable by another mapping. Let's say we have a `NullLogger` that simply ignores the messages passed to it. We want to use this in production, but allow another module to override it during debugging. We can use `toDefault` to map `Logger` to `NullLogger`, which will ensure that `NullLogger` will only be used if another mapping does not exist or is not provided later.

```haxe
class NullLogger implements Logger {
  public function new() {}

  public function log(message:String) {
    // noop
  }
}

class NullLoggerModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    // We still want to mark this as `shared` so it's only created once *if* it is used.
    container.map(Logger).toDefault(NullLogger).share();
  }
}

function main() {
  var container = Container.compile(
    new NullLoggerModule(),
    #if debug
    new SimpleLoggerModule(), 
    #end
    new ValueModule()
  );

  // etc.
}
```

Note that if you *don't* use `toDefault`, mapping a type more than once will cause the Container to fail to compile.

### When Resolved

One final feature to go over is the `when(...).resolved(...)` hook. This allows you to inspect and modify a mapping right before it's resolved by the container, much like an event or a filter. Lets set up our example to track how many times each mapping is instantiated by the container. The `shared` mappings should only be created once, while the others should trigger multiple times.

```haxe
class Tracking implements Module {
  public function new() {}

  public function provide(container:Container) {
    // Note: the first argument is always the value being investigated. The rest of the 
    // arguments, if any, will be injected by the container. If you try to inject a
    // dependency the container does not satisfy you'll get a compiler error.
    container.when(Logger).resolved((logger) -> {
      logger.log('Logger resolved');
      logger;
    });

    var count = 0;
    container.when(Value(String)).resolved((value, logger:Logger) -> {
      count++;
      logger.log('Value<String> has been used ${count} times');
      value;
    });
  }
}

function main() {
  var container = Container.compile(
    new NullLoggerModule(),
    #if debug
    new Tracking(),
    new SimpleLoggerModule(),
    #end
    new ValueModule()
  );

  // etc.
}
```

### Composing Modules

A module can use other modules, and the dependencies those modules provide will be tracked by the Container compiler.

```haxe
class CoreModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.use(NullLoggerModule, ValueModule);
  }
}

function main() {
  var container = Container.compile(
    #if debug
    new Tracking(),
    new SimpleLoggerModule(),
    #end
    new CoreModule()
  );

  // etc.
}
```

Containers composed in this way will be instantiated by the container, which means they can have dependencies of their own. For example, suppose we wanted to add a `Value<Int>` to our container:

```haxe
class IntValueModule implements Module {
  final value:Int;

  public function new(value) {
    this.value = value;
  }

  public function provide(container:Container) {
    container.map(Value(Int)).to(new Value(value));
  }
}
```

If we add this to our `CoreModule` we'll also need to map something to `Int` to get it to compile.

```haxe
class CoreModule implements Module {
  public function new() {}

  public function provide(container:Container) {
    container.map(Int).toDefault(1);
    container.use(NullLoggerModule, ValueModule, IntValueModule);
  }
}
```
