import capsule.Container;

class Test {

  public static function main() {
    var container = new Container();
    container.map(String, 'test').toValue('test');
    container.map(String, 'bar').toValue('bar');
    container.map(Bar).toType(Bar);
    container.map(Foo).toType(Foo);
    var foo = container.get(Foo);
    foo.sayBar();

    var child = container.getChildContainer();
    child.map(String, 'test').toValue('hello');
    child.map(String, 'bar').toValue('francis');
    var foo2 = child.get(Foo);
    foo2.sayBar();
  }

}

class Foo {
  
  @:inject('bar') public var bar:String;
  @:inject public var barable:Bar;
  private var test:String;

  @:inject('test', null) 
  public function new(test:String, ?bar:String) {
    this.test = test;
    if (bar != null) this.bar = bar;
  }

  public function sayBar() {
    trace(test + bar + barable.bar);
  }

}

class Bar {

  public var bar:String;

  public function new() {
    bar = 'bar';
  }

}