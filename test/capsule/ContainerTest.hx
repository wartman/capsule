package capsule;

import capsule.exception.ProviderAlreadyExistsException;
import fixture.*;

using Medic;

class ContainerTest implements TestCase {
  public function new() {}

  @:test('Simple values')
  public function testSimple() {
    var container = new Container();
    container.bind(String).to('foo');
    container.bind(Int).to(1);

    container.get(String).equals('foo');
    container.get(Int).equals(1);
  }

  @:test('Maps classes without dependencies')
  public function testBasicClassBinding() {
    var container = new Container();
    container.bind(SimpleService).to(Simple);
    container.get(SimpleService).getValue().equals('value');
  }

  @:test('Maps classes to instances if provided')
  public function testClassInstanceBinding() {
    var container = new Container();
    
    container.bind(ValueService).to(new Value('foo'));

    container.get(ValueService).get().equals('foo');
  }

  @:test('Classes can have dependencies')
  public function testBasicClassDeps() {
    var container = new Container();

    container.bind(ValueService).to(new Value('dep'));
    container.bind(SimpleService).to(SimpleWithDep);
    
    container.get(SimpleService).getValue().equals('dep');
  }

  @:test('Inline functions can be used as providers')
  public function testBasicInlineFunctionProvider() {
    var container = new Container();

    container.bind(ValueService).to(new Value('dep'));
    container.bind(String).to(function (value:ValueService) {
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

    container.bind(ValueService).to(new Value('dep'));
    container.bind(String).to(namedFunctionProvider);

    container.get(String).equals('dep');
  }

  @:test('Typedefs can be used as identifiers')
  public function testBasicTypedefAsId() {
    var container = new Container();
    container.bind(FooIdentifier).to('foo');
    container.get(FooIdentifier).equals('foo');
  }

  @:test('Can handle type params with a hacky syntax')
  public function testSimpleParams() {
    var container = new Container();
    container.bind(Map(String, String)).to([ 'foo' => 'foo' ]);
    container.get(Map(String, String)).get('foo').equals('foo');
  }

  @:test('Can handle generic classes')
  public function testSimpleGenericClass() {
    var container = new Container();
    container.bind(String).to('foo');
    container.bind(HasParamsService(String)).to(HasParams(String));
    container.get(HasParamsService(String)).getValue().equals('foo');
  }

  @:test('Can figure out when a function is being called instead of the hacky generic syntax')
  public function testFunctionCall() {
    var fun = () -> 'foo';
    var container = new Container();
    container.bind(String).to(fun());
    container.get(String).equals('foo');
  }
  
  @:test('Can handle nested generic classes')
  public function testNestedGenericClass() {
    var container = new Container();
    container.bind(String).to('foo');
    container.bind(HasParamsService(String)).to(HasParams(String));
    container.bind(HasParamsService(HasParamsService(String)))
      .to(HasParams(HasParamsService(String)));
    container.get(HasParamsService(HasParamsService(String)))
      .getValue().getValue().equals('foo');
  }

  @:test('Container.instantiate can inject dependencies')
  public function testSimpleBuild() {
    var container = new Container();
    container.bind(String).to('foo');
    
    var test = container.instantiate(HasParams(String));
    test.getValue().equals('foo');
  }

  @:test('Can extend mappings')
  public function testExtendsBindings() {
    var container = new Container();

    container.bind(String).to('foo');
    container.bind(Int).to(1);
    
    container
      .getBinding(String)
      .extend(value -> container.instantiate((i:Int) -> value + i))
      .share();
    
    container.get(String).equals('foo1');
  }
  
  @:test('Test sharing')
  public function testSharing() {
    var container = new Container();
    var iter = 1;
    
    container.bind(String).to(() -> 'foo' + container.get(Int));
    container.bind(Int).to(() -> iter++);

    container.get(String).equals('foo1');
    container.get(String).equals('foo2');

    container.getBinding(Int).share();

    container.get(String).equals('foo3');
    container.get(String).equals('foo3');
  }
  
  @:test('toShared is available as a shortcut.')
  public function testToShared() {
    var container = new Container();
    var iter = 1;
    
    container.bind(String).to(() -> 'foo' + container.get(Int));
    container.bind(Int).toShared(() -> iter++);

    container.get(String).equals('foo1');
    container.get(String).equals('foo1');
  }

  @:test('Child can override parent')
  public function testChildOverrides() {
    var container = new Container();
    container.bind(String).to('foo');
    container.bind(FooIdentifier).to('bar');
    container.bind(Map(String, String)).to(function (one:String, two:FooIdentifier) {
      return [ 'one' => one, 'two' => two ];
    });

    var expected1 = container.get(Map(String, String));
    expected1.get('one').equals('foo');
    expected1.get('two').equals('bar');

    var child = container.getChild();
    child.bind(String).to('changed');

    var expected2 = child.get(Map(String, String));
    expected2.get('one').equals('changed');
    expected2.get('two').equals('bar');
  }

  @:test('Bindings can be extended before they\'re resolved')
  public function testBindingExtensionsToNullProvider() {
    var container = new Container();
    container.getBinding(String).extend(str -> str + 'bar');
    container.bind(String).to('foo');
    container.get(String).equals('foobar');
  }

  @:test('Bindings that have been resolved will throw an error if you try to remap them')
  public function testBindingToAlreadyResolvedBinding() {
    var container = new Container();
    try {
      container.bind(String).to('foo');
      container.getBinding(String).to('bar');
      Assert.fail('Should have thrown an exception');
    } catch (e:ProviderAlreadyExistsException) {
      Assert.pass();
    }
  }

  @:test('Default mappings can be overriden')
  public function testDefaultBinding() {
    var container = new Container();
    container.bind(String).toDefault('foo');
    container.get(String).equals('foo');
    container.bind(String).to('bar');
    container.get(String).equals('bar');
  }

  @:test('Default mappings will not override existing ones')
  public function testNotOverridingDefaultBinding() {
    var container = new Container();
    container.bind(String).to('bar');
    container.get(String).equals('bar');
    container.bind(String).toDefault('foo');
    container.get(String).equals('bar');
  }

  @:test('Default mappings will forward their extensions')
  public function testDefaultBindingExtensions() {
    var container = new Container();
    container.bind(String).toDefault('foo').extend(value -> value + '_bar');
    container.get(String).equals('foo_bar');
    container.bind(String).to('bar');
    container.get(String).equals('bar_bar');
  }
}
