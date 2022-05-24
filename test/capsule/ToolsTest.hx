package capsule;

import fixture.*;

using Medic;
using capsule.Tools;

class ToolsTest implements TestCase {
  public function new() {}

  @:test('Tools provide .net-style shortcuts')
  function testSimpleTools() {
    var container = new Container()
      .withTransient(String, 'foo');

    container.withTransient(ValueService, Value)
      .withSingleton(SimpleService, SimpleWithDep);
    
    var a = container.get(ValueService);
    var b = container.get(ValueService);

    (a == b).isFalse();

    var a = container.get(SimpleService);
    var b = container.get(SimpleService);

    (a == b).isTrue();
    
    container.get(SimpleService).getValue().equals('foo');
  }

  @:test('Tools allow you to get a list of dependencies')
  function testDeps() {
    var deps = Tools.getDependencies(SimpleWithDep);
    deps.length.equals(1);
    deps[0].equals('fixture.ValueService');
  }
}
