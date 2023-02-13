package capsule;

import fixture.*;

using Medic;

class ModuleTest implements TestCase {
	public function new() {}

	@:test('Modules work')
	public function testSimpleModules() {
		var container = Container.build(new ValueModule('value'), new SimpleModule());
		container.get(SimpleService).getValue().equals('value');
	}

	@:test('Modules track params')
	public function testParamModule() {
		var container = Container.build(new ValueModule('value'), new ParamModule());
		container.get(HasParamsService(ValueService)).getValue().get().equals('value');
	}

	@:test('Modules track composed modules and track their constructor\'s dependencies')
	public function testComposedModules() {
		var container = Container.build(new StringModule('foo'), new ComposedModule());
		container.get(HasParamsService(ValueService)).getValue().get().equals('foo');
	}

	@:test('Modules can track methods outside provide')
	public function testMultiMethods() {
		var container = Container.build(new SeveralMethodsModule());
		container.get(SimpleService).getValue().equals('foo');
	}

	@:test('Modules track default mappings')
	public function testDefaultMappings() {
		var container = Container.build(new SimpleWithDefaultsModule());
		container.get(SimpleService).getValue().equals('foo');
	}

	@:test('Modules can override default mappings')
	public function testOverrideDefaultMappings() {
		var container = Container.build(new SimpleWithDefaultsModule(), new SimpleOverridesDefaultsModule());
		container.get(SimpleService).getValue().equals('override');
	}
}
