package capsule;

import fixture.*;

using Medic;

class ModuleTest implements TestCase {
	public function new() {}

	@:test('Modules work')
	public function testSimpleModules() {
		var container = Container.compile(new ValueModule('value'), new SimpleModule());
		container.open((service:SimpleService) -> {
			service.getValue().equals('value');
		});
	}

	@:test('Compiling works')
	public function testSimpleCompile() {
		var container = Container.compile(new ValueModule('value'), new SimpleModule());
		container.open((service:SimpleService, value:ValueService) -> {
			service.getValue().equals('value');
			value.get().equals('value');
		});
	}

	@:test('Modules track params')
	public function testParamModule() {
		var container = Container.compile(new ValueModule('value'), new ParamModule());
		container.open((params:HasParamsService<ValueService>) -> {
			params.getValue().get().equals('value');
		});
	}

	@:test('Modules track composed modules and track their constructor\'s dependencies')
	public function testComposedModules() {
		var container = Container.compile(new StringModule('foo'), new ComposedModule());
		container.open((params:HasParamsService<ValueService>) -> {
			params.getValue().get().equals('foo');
		});
	}

	@:test('Modules can track methods outside provide')
	public function testMultiMethods() {
		var container = Container.compile(new SeveralMethodsModule());
		container.open((simple:SimpleService) -> {
			simple.getValue().equals('foo');
		});
	}

	@:test('Modules track default mappings')
	public function testDefaultMappings() {
		var container = Container.compile(new SimpleWithDefaultsModule());
		container.open((simple:SimpleService) -> {
			simple.getValue().equals('foo');
		});
	}

	@:test('Modules can override default mappings')
	public function testOverrideDefaultMappings() {
		var container = Container.compile(new SimpleWithDefaultsModule(), new SimpleOverridesDefaultsModule());
		container.open((simple:SimpleService) -> {
			simple.getValue().equals('override');
		});
	}

	@:test('Hooks register dependencies')
	public function testHooksHaveDependencies() {
		var container = Container.compile(new StringModule('foo'), new ValueModule('bar'), new HasHooks());
		container.open((str:String) -> {
			str.equals('foo_bar');
		});
	}
}
