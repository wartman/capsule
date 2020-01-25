package capsule;

import haxe.ds.Map;
import fixture.*;
import fixture.params.*;

using Medic;

class ContainerTest implements TestCase {

  public function new() {}

  @test
  public function testSimpleValue() {
    var container = new Container();
    container.map(String, 'str').toValue('foo');
    container.map(Int, 'one').toValue(1);

    container.get(String, 'str').equals('foo');
    container.get(Int, 'one').equals(1);
  }

  @test
  public function testFactory() {
    var container = new Container();
    container.map(String, 'foo').toFactory(() -> 'foo');
    container.get(String, 'foo').equals('foo');
  }

  @test
  public function testFactoryAutoInjection() {
    var container = new Container();
    container.map(String).toValue('bar');
    container
      .map(String, 'foo')
      .toFactory((bar:String) -> 'foo' + bar);
    container.get(String, 'foo').equals('foobar');
  }

  @test
  public function testFactoryWithParams() {
    var container = new Container();
    container.map('Array<String>').toValue([ 'bar', 'bin' ]);
    container
      .map(String, 'foo')
      .toFactory((bar:Array<String>) -> 'foo' + bar.join(''));
    container.get(String, 'foo').equals('foobarbin');
  }

  @test
  public function testTaggedFactory() {
    var container = new Container();
    container.map(String, 'bar').toValue('bar');
    container
      .map(String, 'foo')
      .toFactory(function (@:inject.tag('bar') bar:String) return 'foo' + bar);
    container.get(String, 'foo').equals('foobar');
  }
  
  @test
  public function testClosure() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(InjectsValues, 'default').toClass(InjectsValues);
    
    var mapping = container.map(InjectsValues, 'local').toClass(InjectsValues);
    mapping.with(c -> c.map(String, 'foo').toValue('changed'));

    var expectedLocal = container.get(InjectsValues, 'local');
    expectedLocal.foo.equals('changed');
    
    var expectedDefault = container.get(InjectsValues, 'default');
    expectedDefault.foo.equals('foo'); 
  }

  @test
  public function testConstructorInjecton() {
    var container = new Container();
    container.map(Plain).toClass(Plain);
    container.map(InjectsConstructor).toClass(InjectsConstructor);
    var expected = container.get(InjectsConstructor).one.value;
    expected.equals('one');
  }

  @test
  public function testBuild() {
    var container = new Container();
    container.map(String).toValue('one');
    container.build('HasParams<String>').foo.equals('one');
  }

  @test
  public function testParams() {
    var container = new Container();
    container.map(String).toValue('one');
    container.map('HasParams<String>').toClass(HasParams);
    
    container.map(Int).toValue(1);
    container.map('HasParams<Int>').toClass(HasParams);
    
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

  @test
  public function testParamsInProps() {
    var container = new Container();
    container.map(String).toValue('one');
    container.map(Int).toValue(1);
    container.map('InjectsPropWithParam<String>').toClass(InjectsPropWithParam);
    container.map('InjectsPropWithParam<Int>').toClass(InjectsPropWithParam);

    container.get('InjectsPropWithParam<String>').foo.equals('one');
    container.get('InjectsPropWithParam<Int>').foo.equals(1);
  }

  @test
  public function testTaggedParams() {
    var container = new Container();
    container.map(String, 'foo').toValue('mapped');
    container.map('HasTaggedParams<String>').toClass(HasTaggedParams);
    container.get('HasTaggedParams<String>').foo.equals('mapped');
  }

  @test
  public function testComplexParams() {
    var container = new Container();
    container.map(Int).toValue(2);
    container.map(String).toValue('bar');
    container.map('BaseParams<Int, String>').toClass(HasComplexParams);
    var expected = container.get('BaseParams<Int, String>');
    expected.foo.equals(2);
    expected.bar.equals('bar');
  }

  @test('Interfaces are correctly resolved')
  public function testWorksOnInterfaces() {
    var container = new Container();
    container.map(Int).toValue(2);
    container.map(String).toValue('bar');
    container.map('BaseParams<Int, String>').toClass(HasComplexParams);
    container.map('UsesBaseParams<Int, String>').toClass(CorrectlyFollowsComplexParams);
    var expected = container.get('UsesBaseParams<Int, String>');
    expected.baseParams.foo.equals(2);
    expected.baseParams.bar.equals('bar');
  }

  @test
  public function testDeepParams() {
    var container = new Container();
    container.map('Map<String, String>').toValue([ 'foo' => 'foo' ]);
    container.map('String').toValue('foo');
    container.map('HasDeepParams<String, String>').toClass(HasDeepParams);
    var expected = container.get('HasDeepParams<String, String>');
    expected.map.get('foo').equals('foo');
    expected.foo.equals('foo');
  }

  @test
  public function testConditionalConstructor() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(ConditionallyInjectsConstructor).toClass(ConditionallyInjectsConstructor);
    var expected = container.get(ConditionallyInjectsConstructor);
    expected.foo.equals('foo');
    expected.bar.equals('bar');
    expected.bax.equals('default');
  }

  @test
  public function testChildOverrides() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(InjectsValues).toClass(InjectsValues);
    var expected1 = container.get(InjectsValues);
    expected1.foo.equals('foo');
    expected1.bar.equals('bar');

    var child = container.getChild();
    child.map(String, 'foo').toValue('changed');
    var expected2 = child.get(InjectsValues);
    expected2.foo.equals('changed');
    expected2.bar.equals('bar');
  }

  @test
  public function testExtend() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(InjectsValues).toClass(InjectsValues);
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

  @test
  public function testMethodInjection() {
    var container = new Container();
    container.map(String).toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(String, 'bin').toValue('bin');
    container.map(String, 'bax').toValue('bax');
    container.map(Plain).toClass(Plain);
    container.map(InjectsMethods).toClass(InjectsMethods);
    var expected = container.get(InjectsMethods);
    expected.foo.equals('foo');
    expected.bar.equals('bar');
    expected.bin.equals('bin');
    expected.bax.equals('bax');
    expected.plain.value.equals('one');
  }

  @test
  public function testPostInjection() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(PostInject).toClass(PostInject);
    var expected = container.get(PostInject);
    expected.ran.equals('foo:one:two:three:four');
  }

  @test
  public function testServiceProviderInstance() {
    var container = new Container();
    container.use(new SimpleServiceProvider());
    var expected = container.get(String, 'foo');
    expected.equals('foo');
  }

  @test
  public function testServiceProvider() {
    var container = new Container();
    container.use(SimpleServiceProvider);
    var expected = container.get(String, 'foo');
    expected.equals('foo');
  }

  @test
  public function testHas() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.has(String, 'foo').isTrue();
    container.has(String, 'nope').isFalse();
  }

  @test
  public function testAbstractsAreHandledRight() {
    var container = new Container();
    container.map(AbstractString).toValue(new AbstractString('foo'));
    container.get(AbstractString).unBox().equals('foo');
  }

  @test
  public function testResolvesTypedefsCorrectly() {
    var container = new Container();
    container.map(StringArray).toValue([ 'foo', 'bar' ]);
    container.has('Array<String>').isFalse();
    container.get(StringArray)[0].equals('foo');
    container.get(StringArray)[1].equals('bar');
  }

  @test
  public function throwsUsefulError() {
    var container = new Container();
    try {
      container.get(String, 'foo');
      Assert.fail('Should have thrown a MappingNotFoundError');  
    } catch (e:MappingNotFoundError) {
      Assert.pass();
    }
  }

  @test
  public function canGetMappings() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.getMapping(String, 'foo').extend(v -> v += 'bar');
    container.get(String, 'foo').equals('foobar');
  }

}
