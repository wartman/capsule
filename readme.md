Capsule
=======

About
-----

Capsule is a simple dependency injection framework for Haxe, built around
the idea that all mappings can be reduced to factory functions. Rather than use
run-time metadata it is entirely macro based.

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
    container.map(Fib, 'specific.fib').toType(Fib);
    // For more fine grained control:
    container.map(Bif).toFactory(container -> new Bif('bof')).asShared();
    container.map(Bar).toType(Bar);
    container.map(Fooable).toType(Fooable);
  }

}

```

In the above example, `container.map(Fooable).toType(Fooable)` becomes the following (more or less):

```haxe
container.mapType('example.Fooable', null).toFactory(container -> {
  var value = new Fooable(
    container.get(example.Bif),
    container.get(example.Fib, 'specific.fib'),
    null
  );
  value.bar = container.get(example.Bar);
  value.bin = container.get(String, 'named');
  value.after();
  return value;
});
```

Useage
------

Mapping types without params is simple:

```haxe
container.map(String).toValue('foo');
container.map(MyClass).toType(MyClass);
```

You can also give mappings a `tag`, which is especially useful
for primitive types (like Strings):

```haxe
container.map(String, 'foo').toValue('foo');
var foo = container.get(String, 'foo');
```

You can also use an alternate, slightly weird syntax to
tag types (which compiles to be exactly the same as the above):

```haxe
container.map(var foo:String).toValue('foo');
var foo = container.get(var foo:String);
```

This `var` syntax makes a bit more sense when you're dealing with
types that have parameters. To explain, let's first note that this 
will not work, due to the limitations of Haxe's syntax:

```haxe
container.map(Map<String, String>).toValue([
  'foo' => 'bar'
]);
```

Instead, you have two options. You can pass a `String` to map or
use the `var` syntax -- and note that an underscore, such as 
`var _:T`, will be treated the same as a mapping without a tag.

```haxe
// String method:
container.map('Map<String, String>').toValue([
  'foo' => 'bar'
]);

// Var method:
container.map(var _:Map<String, String>).toValue([
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
capsule.map('Example<String>').toType(Example);
trace(capsule.get('Example<String>').foo); // => 'foo'
```

This currently does not work with tagging, but that's on the list.
