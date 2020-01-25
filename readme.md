Capsule
=======

[![Build Status](https://travis-ci.com/wartman/capsule.svg?branch=master)](https://travis-ci.com/wartman/capsule)

Capsule is a simple dependency injection framework for Haxe, built around
the idea that all mappings can be reduced to factory functions. Rather than use
run-time metadata it is entirely macro based.

About
-----

For example, take this class:

```haxe
package example;

class Fooable {

  @:inject public var bar:Bar;
  @:inject('named') public var bin:String;
  private var bif:Bif;
  private var fib:Fib;

  // Constructors are ALWAYS injected, so we 
  // don't need to mark them.
  public function new(
    bif:Bif,
    // We can mark arguments if the need a tag: 
    @:inject.tag('specific.fib') fib:Fib,
    // ... or tell the Container to skip an argument, so long
    // as it is nullable.
    @:inject.skip ?optional:String
  ) {
    this.bif = bif;
    this.fib = fib;
  }

  @:inject.post(1) public function after() {
    trace(bin);
  }

}

```

Now let's map it to the container:

```haxe
import capsule.Container;
import example.Fooable;
import example.Bar;
import example.Bif;
import example.Fib;

class Main {

  public static function main() {
    var container = new Container();
    container.map(String, 'named').toValue('bin');
    container.map(Fib, 'specific.fib').toClass(Fib);
    // For more fine grained control:
    container.map(Bif).toFactory(container -> new Bif('bof')).asShared();
    container.map(Bar).toClass(Bar);
    container.map(Fooable).toClass(Fooable);
  }

}

```

In the above example, `container.map(Fooable).toClass(Fooable)` becomes the following (more or less):

```haxe
container.addMapping(new container.Mapping(
  new container.Identifier('example.Fooable', null),
  ProvideFactory(container -> {
    var value = new Fooable(
      container.get(example.Bif),
      container.get(example.Fib, 'specific.fib'),
      null
    );
    value.bar = container.get(example.Bar);
    value.bin = container.get(String, 'named');
    value.after();
    return value;
  })
));
```

Mapping
-------

Mapping types is simple:

```haxe
container.map(String).toValue('foo');
container.map(MyClass).toClass(MyClass);
```

You can also give mappings a `tag`, which is especially useful
for primitive types (like Strings):

```haxe
container.map(String, 'foo').toValue('foo');
var foo = container.get(String, 'foo');
```

An issue you may run into are type parameters. The following syntax will not work
with Haxe:

```haxe
// This will not compile, and haxe will throw something like
// `expected an expression`:
container.map(Map<String, String>).toValue([
  'foo' => 'bar'
]);
```

There are two ways around this. The first is to create a `typedef`:

```haxe

typedef StringMap = Map<String, String>;

container.map(StringMap).toValue([
  'foo' => 'bar'
]);

```

This is a bit clumsy, however, so Capsule will also let you pass a string to `map` which it will then parse into the correct type:

```haxe
container.map('Map<String, String>').toValue([
  'foo' => 'bar'
]);
```

Note that both of these methods will be typed correctly, so
`toValue` will expect a `Map<String, String>`.

Capsule will also automagically resolve parameters for you, so
something like this should work:

```haxe
class Example<T> {

  var foo:T;

  public function new(foo:T) {
    this.foo = foo;
  }

}

capsule.map(String).toValue('foo');
capsule.map('Example<String>').toClass(Example);
trace(capsule.get('Example<String>').foo); // => 'foo'
```

This will even work with tags:

```haxe
class Example<T> {

  var foo:T;

  public function new(@:inject.tag('foo') foo:T) {
    this.foo = foo;
  }

}

capsule.map(String, 'foo').toValue('foo');
capsule.map('Example<String>').toClass(Example);
trace(capsule.get('Example<String>').foo); // => 'foo'
```

For more fine-grained injection, you can use the `toFactory` mapping.
Any function passed to `toFactory` will be automagically injected for
you (Note that arrow functions do not work with metadata):

```haxe
capsule.map(String, 'foo').toValue('foo');
capsule.map('Example<String>').toFactory(function (
  @:inject.tag('foo') foo:String
) {
  var example = new Example(foo);
  trace(example);
  return example;
});
```

`toFactory` will NOT work if you pass in a reference to a function or a method.

```haxe
// This will not work:
var foo = function (
  @:inject.tag('foo') foo:String
) {
  var example = new Example(foo);
  trace(example);
  return example;
};
capsule.map('Example<String>').toFactory(foo);
```

If a mapping does not exist, Capsule will throw a `capsule.MappingNotFoundError`. Set `-D debug` in your HXML to get position info with these errors.

ServiceProviders
----------------

A `capsule.ServiceProvider` is a simple way to, well, provide services.

To create a ServiceProvider, simply implement the interface:

```haxe
import capsule.Container;
import capsule.ServiceProvider;

class FooProvider implements ServiceProvider {

  final foo:String;

  public function new(foo) {
    this.foo = foo;
  }

  public function register(container:Container) {
    container.map(String, 'foo').toValue(foo);
  }

}
```

... and then pass it to a Container using `Container#use`:

```haxe
var container = new capsule.Container();
container.use(new FooProvider('foo'));
trace(container.get(String, 'foo')) // => 'foo';
```

If you don't need to configure your service provider, you can just pass the class directly to `Container#use`:

```haxe
class SimpleProvider implements capsule.ServiceProvider {

  public function new() {}

  public function register(container:capsule.Container) {
    container.map(String, 'foo').toValue('foo');
  }
  
}

var container = new capsule.Container();
container.use(SimpleProvider);
trace(container.get(String, 'foo')) // => 'foo';
```
