package test.capsule;

import capsule.Container;
import test.fixture.*;

using hex.unittest.assertion.Assert;

class ContainerTest {

  @Test
  public function testSimpleValue() {
    var container = new Container();
    container.map(String, 'str').toValue('foo');
    container.map(Int, 'one').toValue(1);

    container.get(String, 'str').equals('foo');
    container.get(Int, 'one').equals(1);
  }

  @Test
  public function testAlternateMethodOfTagging() {
    var container = new Container();
    container.map(var str:String).toValue('foo');
    container.map(var one:Int).toValue(1);

    container.get(var str:String).equals('foo');
    container.get(var one:Int).equals(1);

  }

  @Test
  public function testFactory() {
    var container = new Container();
    container.map(String, 'foo').toFactory(container -> 'foo');
    container.get(String, 'foo').equals('foo');
  }

  @Test
  public function testClosure() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(InjectsValues, 'default').toType(InjectsValues);
    
    var mapping = container.map(InjectsValues, 'local').toType(InjectsValues);
    mapping.map(String, 'foo').toValue('changed');

    var expectedLocal = container.get(InjectsValues, 'local');
    expectedLocal.foo.equals('changed');
    
    var expectedDefault = container.get(InjectsValues, 'default');
    expectedDefault.foo.equals('foo'); 
  }

  @Test
  public function testConstructorInjecton() {
    var container = new Container();
    container.map(Plain).toType(Plain);
    container.map(InjectsConstructor).toType(InjectsConstructor);
    var expected = container.get(InjectsConstructor).one.value;
    expected.equals('one');
  }

  @Test
  public function testParams() {
    var container = new Container();
    container.map(String).toValue('one');
    container.map('HasParams<String>').toType(HasParams);
    
    container.map(Int).toValue(1);
    container.map('HasParams<Int>').toType(HasParams);
    
    var expected = container.get('HasParams<String>');
    expected.foo.equals('one');
    var expected = container.get('HasParams<Int>');
    expected.foo.equals(1);

    // Typing should work here!
    container.map('Map<String, String>', 'things').toValue([
      'foo' => 'bar',
      'bar' => 'bin'
    ]);
    var things = container.get('Map<String, String>', 'things');
    things.get('foo').equals('bar');
  }

  @Test
  public function testParamsWithAlternateVars() {
    var container = new Container();
    container.map(String).toValue('one');
    container
      .map(var _:HasParams<String>)
      .toType(HasParams);
    container.map(Int).toValue(1);
    container
      .map(var _:HasParams<Int>)
      .toType(HasParams);
    var expected = container.get(var _:HasParams<String>);
    expected.foo.equals('one');
    var expected = container.get(var _:HasParams<Int>);
    expected.foo.equals(1);

    container.map(var things:Map<String, String>).toValue([
      'foo' => 'bar',
      'bar' => 'bin'
    ]);
    var things = container.get(var things:Map<String, String>);
    things.get('foo').equals('bar');
  }

  @Test
  public function testConditionalConstructor() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(ConditionallyInjectsConstructor).toType(ConditionallyInjectsConstructor);
    var expected = container.get(ConditionallyInjectsConstructor);
    expected.foo.equals('foo');
    expected.bar.equals('bar');
    expected.bax.equals('default');
  }

  @Test
  public function testChildOverrides() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(InjectsValues).toType(InjectsValues);
    var expected1 = container.get(InjectsValues);
    expected1.foo.equals('foo');
    expected1.bar.equals('bar');

    var child = container.getChild();
    child.map(String, 'foo').toValue('changed');
    var expected2 = child.get(InjectsValues);
    expected2.foo.equals('changed');
    expected2.bar.equals('bar');
  }

  @Test
  public function testExtend() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(InjectsValues).toType(InjectsValues);
    var expected1 = container.get(InjectsValues);
    expected1.foo.equals('foo');
    expected1.bar.equals('bar');

    var container2 = new Container();
    container2.map(String, 'foo').toValue('changed');
    var container3 = container2.extend(container);
    var expected2 = container3.get(InjectsValues);
    expected2.foo.equals('changed');
    expected2.bar.equals('bar');
  }

  @Test
  public function testMethodInjection() {
    var container = new Container();
    container.map(String).toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(String, 'bin').toValue('bin');
    container.map(String, 'bax').toValue('bax');
    container.map(Plain).toType(Plain);
    container.map(InjectsMethods).toType(InjectsMethods);
    var expected = container.get(InjectsMethods);
    expected.foo.equals('foo');
    expected.bar.equals('bar');
    expected.bin.equals('bin');
    expected.bax.equals('bax');
    expected.plain.value.equals('one');
  }

  @Test
  public function testPostInjection() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(PostInject).toType(PostInject);
    var expected = container.get(PostInject);
    expected.ran.equals('foo:one:two:three:four');
  }

  @Test
  public function testServiceProvider() {
    var container = new Container();
    container.use(new SimpleServiceProvider());
    var expected = container.get(String, 'foo');
    expected.equals('foo');
  }

}
