Capsule
=======

**Note: don't use this yet! It's a bit of a mess, especially in macro land.**

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
    @:inject('specific.fib') fib:Fib,
    // ... or tell the Container to skip an argument, so long
    // as it is nullable.
    @:noInject ?optional:String
  ) {
    this.bif = bif;
    this.fib = fib;
  }

  @:postInject(1) public function after() {
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

To Do
-----

Everything, really, but:

- Some way to check dependencies at runtime
- Sane error checking
