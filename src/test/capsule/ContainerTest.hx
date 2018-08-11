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

  public function testClosure() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(InjectsValues, 'default').toType(InjectsValues);
    
    var mapping = container.map(InjectsValues, 'local').toType(InjectsValues);
    mapping.map(String, 'foo').toValue('changed');

    var expectedLocal = container.get(InjectsValues, 'local');
    assertEquals(expectedLocal.foo, 'changed');
    
    var expectedDefault = container.get(InjectsValues, 'default');
    assertEquals(expectedDefault.foo, 'foo'); 
  }

  public function testConstructorInjecton() {
    var container = new Container();
    container.map(Plain).toType(Plain);
    container.map(InjectsConstructor).toType(InjectsConstructor);
    var expected = container.get(InjectsConstructor).one.value;
    assertEquals(expected, 'one');
  }

  public function testConditionalConstructor() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(ConditionallyInjectsConstructor).toType(ConditionallyInjectsConstructor);
    var expected = container.get(ConditionallyInjectsConstructor);
    assertEquals(expected.foo, 'foo');
    assertEquals(expected.bar, 'bar');
    assertEquals(expected.bax, 'default');
  }

  public function testChildOverrides() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(InjectsValues).toType(InjectsValues);
    var expected1 = container.get(InjectsValues);
    assertEquals(expected1.foo, 'foo');
    assertEquals(expected1.bar, 'bar');

    var child = container.getChild();
    child.map(String, 'foo').toValue('changed');
    var expected2 = child.get(InjectsValues);
    assertEquals(expected2.foo, 'changed');
    assertEquals(expected2.bar, 'bar');
  }

  public function testExtend() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(InjectsValues).toType(InjectsValues);
    var expected1 = container.get(InjectsValues);
    assertEquals(expected1.foo, 'foo');
    assertEquals(expected1.bar, 'bar');

    var container2 = new Container();
    container2.map(String, 'foo').toValue('changed');
    var container3 = container2.extend(container);
    var expected2 = container3.get(InjectsValues);
    assertEquals(expected2.foo, 'changed');
    assertEquals(expected2.bar, 'bar');
  }

  public function testMethodInjection() {
    var container = new Container();
    container.map(String).toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(String, 'bin').toValue('bin');
    container.map(String, 'bax').toValue('bax');
    container.map(Plain).toType(Plain);
    container.map(InjectsMethods).toType(InjectsMethods);
    var expected = container.get(InjectsMethods);
    assertEquals(expected.foo, 'foo');
    assertEquals(expected.bar, 'bar');
    assertEquals(expected.bin, 'bin');
    assertEquals(expected.bax, 'bax');
    assertEquals(expected.plain.value, 'one');
  }

  public function testPostInjection() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(PostInject).toType(PostInject);
    var expected = container.get(PostInject);
    assertEquals(expected.ran, 'foo:one:two:three:four');
  }

  // todo:
  // all the tests
}
