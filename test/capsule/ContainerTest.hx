package capsule;

import capsule.exception.ProviderAlreadyExistsException;
import fixture.*;

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
		container.map(String).to(function(value:ValueService) {
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

	@:test('Can handle type params with a hacky syntax')
	public function testSimpleParams() {
		var container = new Container();
		container.map(Map(String, String)).to(['foo' => 'foo']);
		container.get(Map(String, String)).get('foo').equals('foo');
	}

	@:test('Can handle generic classes')
	public function testSimpleGenericClass() {
		var container = new Container();
		container.map(String).to('foo');
		container.map(HasParamsService(String)).to(HasParams(String));
		container.get(HasParamsService(String)).getValue().equals('foo');
	}

	@:test('Can figure out when a function is being called instead of the hacky generic syntax')
	public function testFunctionCall() {
		var fun = () -> 'foo';
		var container = new Container();
		container.map(String).to(fun());
		container.get(String).equals('foo');
	}

	@:test('Can handle nested generic classes')
	public function testNestedGenericClass() {
		var container = new Container();
		container.map(String).to('foo');
		container.map(HasParamsService(String)).to(HasParams(String));
		container.map(HasParamsService(HasParamsService(String))).to(HasParams(HasParamsService(String)));
		container.get(HasParamsService(HasParamsService(String)))
			.getValue()
			.getValue()
			.equals('foo');
	}

	@:test('Container.instantiate can inject dependencies')
	public function testSimpleBuild() {
		var container = new Container();
		container.map(String).to('foo');

		var test = container.instantiate(HasParams(String));
		test.getValue().equals('foo');
	}

	@:test('Can extend mappings')
	public function testExtendsMappings() {
		var container = new Container();

		container.map(String).to('foo').share();
		container.map(Int).to(1);

		container.when(String).resolved((i:Int) -> value + i);

		container.get(String).equals('foo1');
	}

	@:test('Test sharing')
	public function testSharing() {
		var container = new Container();
		var iter = 1;

		container.map(String).to(() -> 'foo' + container.get(Int));
		container.map(Int).to(() -> iter++);

		container.get(String).equals('foo1');
		container.get(String).equals('foo2');

		container.map(Int).share();

		container.get(String).equals('foo3');
		container.get(String).equals('foo3');
	}

	@:test('toShared is available as a shortcut.')
	public function testToShared() {
		var container = new Container();
		var iter = 1;

		container.map(String).to(() -> 'foo' + container.get(Int));
		container.map(Int).toShared(() -> iter++);

		container.get(String).equals('foo1');
		container.get(String).equals('foo1');
	}

	@:test('Shared mappings on a container do not get used by a clone')
	public function testChildDoesNotShareWithParent() {
		var container = new Container();
		container.map(Array(Int)).to(() -> [1, 2, 3]).share();

		var value = container.get(Array(Int));
		value.length.equals(3);
		value.push(4);
		container.get(Array(Int)).length.equals(4);

		var child = container.clone();
		child.get(Array(Int)).length.equals(3);

		container.when(Array(Int)).resolved(() -> {
			value.push(5);
			return value;
		});
		container.get(Array(Int)).length.equals(5);
		container.clone().get(Array(Int)).length.equals(4);
	}

	@:test('Mappings can be extended before they\'re resolved')
	public function testMappingExtensionsToNullProvider() {
		var container = new Container();
		container.when(String).resolved(() -> value + 'bar');
		container.map(String).to('foo');
		container.get(String).equals('foobar');
	}

	@:test('Mappings that have been resolved will throw an error if you try to remap them')
	public function testMappingToAlreadyResolvedMapping() {
		var container = new Container();
		try {
			container.map(String).to('foo');
			container.map(String).to('bar');
			Assert.fail('Should have thrown an exception');
		} catch (e:ProviderAlreadyExistsException) {
			Assert.pass();
		}
	}

	@:test('Default mappings can be overridden')
	public function testDefaultMapping() {
		var container = new Container();
		container.map(String).toDefault('foo');
		container.get(String).equals('foo');
		container.map(String).to('bar');
		container.get(String).equals('bar');
	}

	@:test('Default mappings will not override existing ones')
	public function testNotOverridingDefaultMapping() {
		var container = new Container();
		container.map(String).to('bar');
		container.get(String).equals('bar');
		container.map(String).toDefault('foo');
		container.get(String).equals('bar');
	}

	@:test('Default mappings will forward their extensions')
	public function testDefaultMappingExtensions() {
		var container = new Container();
		container.map(String).toDefault('foo');
		container.when(String).resolved(() -> value + '_bar');
		container.get(String).equals('foo_bar');
		container.map(String).to('bar');
		container.get(String).equals('bar_bar');
	}
}
