Capsule
=======

**Note: don't use this yet! It's a bit of a mess, especially in macro land.**

About
-----

Capsule is a simple dependency injection framework for Haxe, built around
the idea that all mappings can be reduced to factory functions. Rather than use
run-time metadata it is entirely macro based.

For example, take this class:

```
package example;

class Fooable {

  @:inject public var bar:Bar;
  @:inject('named') public var bin:String;
  private var fib:Fib;

  @:inject('specific.fib', null)
  public function new(fib:Fib, ?optional:String) {
    this.fib = fib;
  }

  @:post(1) public function after() {
    trace(bin);
  }

}

```

Now let's map it to the container:

```
// In `Main.hx`

import capsule.Container;
import example.Fooable;
import example.Bar;
import example.Fib;

class Main {

  public static function main() {
    var container = new Container();
    container.map(String, 'named').toValue('bin');
    container.map(Fib, 'specific.fib').toType(Fib);
    container.map(Fooable).toType(Fooable);
  }

}

```

In the above example, `container.map(Fooable).toType(Fooable)` becomes the following (more or less):

```
container.mapType('example.Fooable', null).toFactory(function (container) {
  var value = new Fooable(container.get(example.Fib, 'specific.fib'), null);
  value.bar = container.get(example.Bar);
  value.bin = container.get(String, 'named');
  value.after();
  return value;
});
```

Basically, `toType` is a macro that inspects the type passed to it and generates a factory function
based on the type's meta-data (`map` is also a macro that automatically generates an ID based on a type).

To Do
-----

Everything, really, but:

- Some way to check dependencies at runtime
- Sane error checking
- Implementing `@:post` functionality
- Implementing constructor injection a bit better, maybe more like:
```
class Foo {

  public function new(
    @:inject('foo') foo:String,
    @:inject bar:Bar,
    ?optional:Bool
  ) {
    // code
  }

}
```
