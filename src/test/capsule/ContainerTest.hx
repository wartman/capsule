package test.capsule;

import haxe.unit.TestCase;
import capsule.Container;
import test.fixture.*;

class ContainerTest extends TestCase {

  public function testSimpleValue() {
    var container = new Container();
    container.map(String, 'str').toValue('foo');
    container.map(Int, 'one').toValue(1);

    assertEquals(container.get(String, 'str'), 'foo');
    assertEquals(container.get(Int, 'one'), 1);
  }

  public function testConstructorInjecton() {
    var container = new Container();
    container.map(Plain).toType(Plain);
    container.map(InjectsConstructor).toType(InjectsConstructor);
    var expected = container.get(InjectsConstructor).one.value;
    assertEquals(expected, 'one');
  }

  public function testChildOverrides() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(InjectsValues).toType(InjectsValues);
    var expected1 = container.get(InjectsValues);
    assertEquals(expected1.foo, 'foo');
    assertEquals(expected1.bar, 'bar');

    var child = container.getChildContainer();
    child.map(String, 'foo').toValue('bar');
    var expected2 = child.get(InjectsValues);
    assertEquals(expected2.foo, 'bar');
    assertEquals(expected2.bar, 'bar');
  }

  // todo:
  // all the tests
}
