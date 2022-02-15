package capsule;

import fixture.*;

using Medic;

class ModuleTest implements TestCase {
  public function new() {}

  @:test('Modules work')
  public function testSimpleModules() {
    var container = Container.build(
      new ValueModule('value'),
      new SimpleModule()
    );
    container.get(SimpleService).getValue().equals('value');
  }

  @:test('Modules track params')
  public function testParamModule() {
    var container = Container.build(
      new ValueModule('value'),
      new ParamModule()
    );
    container.get(HasParamsService(ValueService)).getValue().get().equals('value');
  }

  @:test('Modules track composed modules and track their constructor\'s dependencies')
  public function testComposedModules() {
    var container = Container.build(
      new StringModule('foo'),
      new ComposedModule()
    );
    container.get(HasParamsService(ValueService)).getValue().get().equals('foo');
  }
}
