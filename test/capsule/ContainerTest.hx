package capsule;

import capsule.exception.ProviderAlreadyExistsException;
import fixture.*;
import utest.*;

using utest.Assert;

class ContainerTest extends Test {
	public function testSimple() {
		var container = new Container();
		container.bind(String).to('foo');
		container.bind(Int).to(1);

		container.get(String).equals('foo');
		container.get(Int).equals(1);
	}

	public function testBasicClassBinding() {
		var container = new Container();
		container.bind(SimpleService).to(Simple);
		container.get(SimpleService).getValue().equals('value');
	}

	public function testClassInstanceBinding() {
		var container = new Container();

		container.bind(ValueService).to(new Value('foo'));

		container.get(ValueService).get().equals('foo');
	}

	public function testBasicClassDeps() {
		var container = new Container();

		container.bind(ValueService).to(new Value('dep'));
		container.bind(SimpleService).to(SimpleWithDep);

		container.get(SimpleService).getValue().equals('dep');
	}

	public function testBasicInlineFunctionProvider() {
		var container = new Container();

		container.bind(ValueService).to(new Value('dep'));
		container.bind(String).to(function(value:ValueService) {
			return value.get();
		});

		container.get(String).equals('dep');
	}

	function namedFunctionProvider(value:ValueService) {
		return value.get();
	}

	public function testBasicNamedFunctionProvider() {
		var container = new Container();

		container.bind(ValueService).to(new Value('dep'));
		container.bind(String).to(namedFunctionProvider);

		container.get(String).equals('dep');
	}

	public function testBasicTypedefAsId() {
		var container = new Container();
		container.bind(FooIdentifier).to('foo');
		container.get(FooIdentifier).equals('foo');
	}

	public function testSimpleParams() {
		var container = new Container();
		container.bind(Map(String, String)).to(['foo' => 'foo']);
		container.get(Map(String, String)).get('foo').equals('foo');
	}

	public function testSimpleGenericClass() {
		var container = new Container();
		container.bind(String).to('foo');
		container.bind(HasParamsService(String)).to(HasParams(String));
		container.get(HasParamsService(String)).getValue().equals('foo');
	}

	public function testFunctionCall() {
		var fun = () -> 'foo';
		var container = new Container();
		container.bind(String).to(fun());
		container.get(String).equals('foo');
	}

	public function testNestedGenericClass() {
		var container = new Container();
		container.bind(String).to('foo');
		container.bind(HasParamsService(String)).to(HasParams(String));
		container.bind(HasParamsService(HasParamsService(String))).to(HasParams(HasParamsService(String)));
		container.get(HasParamsService(HasParamsService(String)))
			.getValue()
			.getValue()
			.equals('foo');
	}

	public function testSimpleInstantiate() {
		var container = new Container();
		container.bind(String).to('foo');

		var test = container.instantiate(HasParams(String));
		test.getValue().equals('foo');
	}

	public function testExtendsBindings() {
		var container = new Container();

		container.bind(String).to('foo').share();
		container.bind(Int).to(1);

		container.when(String).resolved((value, i:Int) -> value + i);

		container.get(String).equals('foo1');
	}

	public function testSharing() {
		var container = new Container();
		var iter = 1;

		container.bind(String).to(() -> 'foo' + container.get(Int));
		container.bind(Int).to(() -> iter++);

		container.get(String).equals('foo1');
		container.get(String).equals('foo2');

		container.bind(Int).share();

		container.get(String).equals('foo3');
		container.get(String).equals('foo3');
	}

	public function testToShared() {
		var container = new Container();
		var iter = 1;

		container.bind(String).to(() -> 'foo' + container.get(Int));
		container.bind(Int).toShared(() -> iter++);

		container.get(String).equals('foo1');
		container.get(String).equals('foo1');
	}

	public function testChildDoesNotShareWithParent() {
		var container = new Container();
		container.bind(Array(Int)).to(() -> [1, 2, 3]).share();

		var value = container.get(Array(Int));
		value.length.equals(3);
		value.push(4);
		container.get(Array(Int)).length.equals(4);

		var child = container.clone();
		child.get(Array(Int)).length.equals(3);

		container.when(Array(Int)).resolved(value -> {
			value.push(5);
			return value;
		});
		container.get(Array(Int)).length.equals(5);
		container.clone().get(Array(Int)).length.equals(4);
	}

	public function testBindingExtensionsToNullProvider() {
		var container = new Container();
		container.when(String).resolved(value -> value + 'bar');
		container.bind(String).to('foo');
		container.get(String).equals('foobar');
	}

	public function testBindingToAlreadyResolvedBinding() {
		var container = new Container();
		try {
			container.bind(String).to('foo');
			container.bind(String).to('bar');
			Assert.fail('Should have thrown an exception');
		} catch (e:ProviderAlreadyExistsException) {
			Assert.pass();
		}
	}

	public function testDefaultBinding() {
		var container = new Container();
		container.bind(String).toDefault('foo');
		container.get(String).equals('foo');
		container.bind(String).to('bar');
		container.get(String).equals('bar');
	}

	public function testNotOverridingDefaultBinding() {
		var container = new Container();
		container.bind(String).to('bar');
		container.get(String).equals('bar');
		container.bind(String).toDefault('foo');
		container.get(String).equals('bar');
	}

	public function testDefaultBindingExtensions() {
		var container = new Container();
		container.bind(String).toDefault('foo');
		container.when(String).resolved(value -> value + '_bar');
		container.get(String).equals('foo_bar');
		container.bind(String).to('bar');
		container.get(String).equals('bar_bar');
	}

	public function testResolvedHook() {
		var container = new Container();

		container.when(Array(String)).resolved(value -> {
			value.push('bar');
			value;
		});
		container.bind(Array(String)).to(() -> ['foo']).share();

		container.get(Array(String)).join('_').equals('foo_bar');
		container.get(Array(String)).join('_').equals('foo_bar');
	}

	public function testNeedsHook() {
		var container = new Container();
		container.bind(String).to('bar');
		container.bind(HasParams(String)).to(HasParams(String));
		container.when(HasParams(String)).needs(String).give('foo');
		container.get(HasParams(String)).getValue().equals('foo');
		container.get(String).equals('bar');
	}

	public function testComplexNeedsHook() {
		var container = new Container();
		container.bind(String).to('bar');
		container.bind(Int).to(3);
		container.bind(HasParams(String)).to(HasParams(String)).share();
		container.when(HasParams(String))
			.needs(String)
			.give((previous:String, int:Int) -> '${previous}_foo_${int}');
		container.when(HasParams(String))
			.needs(Int)
			.give(2);

		container.get(HasParams(String)).getValue().equals('bar_foo_2');
		container.get(String).equals('bar');
		container.get(Int).equals(3);
	}
}
