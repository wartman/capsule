package capsule2;

import fixture2.*;

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
}