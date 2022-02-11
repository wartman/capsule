package capsule2;

import fixture2.*;

using Medic;

class ContainerTest implements TestCase {
  public function new() {}

  @:test('Simple values')
  public function testSimple() {
    var container = new Container();
    container.map(String).to('foo');
    container.map(Int).to(1);

    container.get(String).equals('foo');
    container.get(Int).equals(1);
  }

  @:test('Maps classes without dependencies')
  public function testBasicClassMapping() {
    var container = new Container();
    container.map(SimpleService).to(Simple);
    container.get(SimpleService).getValue().equals('value');
  }

  @:test('Maps classes to instances if provided')
  public function testClassInstanceMapping() {
    var container = new Container();
    
    container.map(ValueService).to(new Value('foo'));

    container.get(ValueService).get().equals('foo');
  }

  @:test('Classes can have dependencies')
  public function testBasicClassDeps() {
    var container = new Container();

    container.map(ValueService).to(new Value('dep'));
    container.map(SimpleService).to(SimpleWithDep);
    
    container.get(SimpleService).getValue().equals('dep');
  }

  @:test('Inline functions can be used as providers')
  public function testBasicInlineFunctionProvider() {
    var container = new Container();

    container.map(ValueService).to(new Value('dep'));
    container.map(String).to(function (value:ValueService) {
      return value.get();
    });

    container.get(String).equals('dep');
  }

  function namedFunctionProvider(value:ValueService) {
    return value.get();
  }

  @:test('Named functions can be used as providers')
  public function testBasicNamedFunctionProvider() {
    var container = new Container();

    container.map(ValueService).to(new Value('dep'));
    container.map(String).to(namedFunctionProvider);

    container.get(String).equals('dep');
  }

  @:test('Typedefs can be used as identifiers')
  public function testBasicTypedefAsId() {
    var container = new Container();
    container.map(FooIdentifier).to('foo');
    container.get(FooIdentifier).equals('foo');
  }
}
