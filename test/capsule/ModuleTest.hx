package capsule;

import fixture.*;
import utest.*;

using utest.Assert;

class ModuleTest extends Test {
	public function testSimpleModules() {
		var container = Container.compile(new ValueModule('value'), new SimpleModule());
		container.get(SimpleService).getValue().equals('value');
	}

	public function testSimpleCompile() {
		var container = Container.compile(new ValueModule('value'), new SimpleModule());
		container.open((service:SimpleService, value:ValueService) -> {
			service.getValue().equals('value');
			value.get().equals('value');
		});
	}

	public function testParamModule() {
		var container = Container.compile(new ValueModule('value'), new ParamModule());
		container.open((params:HasParamsService<ValueService>) -> {
			params.getValue().get().equals('value');
		});
	}

	public function testComposedModules() {
		var container = Container.compile(new StringModule('foo'), new ComposedModule());
		container.open((params:HasParamsService<ValueService>) -> {
			params.getValue().get().equals('foo');
		});
	}

	public function testMultiMethods() {
		var container = Container.compile(new SeveralMethodsModule());
		container.open((simple:SimpleService) -> {
			simple.getValue().equals('foo');
		});
	}

	public function testDefaultBindings() {
		var container = Container.compile(new SimpleWithDefaultsModule());
		container.open((simple:SimpleService) -> {
			simple.getValue().equals('foo');
		});
	}

	public function testOverrideDefaultBindings() {
		var container = Container.compile(new SimpleWithDefaultsModule(), new SimpleOverridesDefaultsModule());
		container.open((simple:SimpleService) -> {
			simple.getValue().equals('override');
		});
	}

	public function testHooksHaveDependencies() {
		var container = Container.compile(new StringModule('foo'), new ValueModule('bar'), new HasHooks());
		container.open((str:String) -> {
			str.equals('foo_bar');
		});
	}

	public function testModulesCanBeSubclassed() {
		var container = Container.compile(new SubClassedModule());
		container.open((simple:SimpleService) -> {
			simple.getValue().equals('foo');
		});
	}
}
