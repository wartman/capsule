import fixture.Simple;
import fixture.AbstractString;
import capsule2.Container;

function main() {
  var container = new Container();
  container.map(AbstractString).to(new AbstractString('foo'));
  container.map(Simple).to(Simple).with(c -> c.map(String).to('foo'));
  container.map(Stuff).to(stuffProvider).share();
  container.map(FooService).to(Foo);
  container.map(FooBarService).to(FooBar).share();
  container.map(OtherThing).to(function (foobar:FooBarService, bin:Map<String, String>) {
    return new OtherThing(foobar.getFooBar());
  });
}

typedef Stuff = Map<String, String>; 

// We can use functions to provide things now!
function stuffProvider(foo:FooService, str:AbstractString):Stuff {
  return [ 'a' => 'stuff', 'b' => foo.getFoo(), 'c' => str.unBox() ];
}

interface FooService {
  public function getFoo():String;
}

class Foo implements FooService {
  public function new() {}

  public function getFoo() {
    return 'foo';
  }
}

interface FooBarService {
  public function getFooBar():String;
}

class FooBar implements FooBarService {
  final foo:FooService;

  public function new(foo) {
    this.foo = foo;
  }

  public function getFooBar() {
    return '${foo.getFoo()}bar';
  }
}

class OtherThing {
  var thing:String;

  public function new(thing) {
    this.thing = thing;
  }
}
