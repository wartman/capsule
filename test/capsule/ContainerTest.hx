package capsule;

import haxe.ds.Map;
import fixture.*;
import fixture.params.*;

using medic.Assert;

class ContainerTest {

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
  public function testAlternateMethodOfTagging() {
    var container = new Container();
    container.map(var str:String).toValue('foo');
    container.map(var one:Int).toValue(1);

    container.get(var str:String).equals('foo');
    container.get(var one:Int).equals(1);

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
    container.map(var _:Array<String>).toValue([ 'bar', 'bin' ]);
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
  public function testNonInlineFactory() {
    var container = new Container();
    var factory = (foo:String) -> foo + 'bar';
    container.map(String).toValue('foo');
    container.map(String, 'foobar').toFactory(factory);
    container.get(String, 'foobar').equals('foobar');
  }
  
  // @test
  // public function testNonInlineFactoryWithMeta() {
  //   var container = new Container();
  //   function factory(@:inject.tag('foo') foo:String) return foo + 'bar';
  //   container.map(String, 'foo').toValue('foo');
  //   container.map(String, 'foobar').toFactory(factory);
  //   container.get(String, 'foobar').equals('foobar');
  // }

  function factoryMethod(foo:String, bar:Int) {
    return foo + ' ' + bar;
  }

  @test
  public function testClassMethodAsFactory() {
    var container = new Container();
    container.map(String).toValue('foo');
    container.map(Int).toValue(1);
    container.map(String, 'foo1').toFactory(factoryMethod);
    container.get(String, 'foo1').equals('foo 1');
  }

  @test
  public function testClosure() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(String, 'bar').toValue('bar');
    container.map(InjectsValues, 'default').toType(InjectsValues);
    
    var mapping = container.map(InjectsValues, 'local').toType(InjectsValues);
    mapping.with(c -> c.map(String, 'foo').toValue('changed'));

    var expectedLocal = container.get(InjectsValues, 'local');
    expectedLocal.foo.equals('changed');
    
    var expectedDefault = container.get(InjectsValues, 'default');
    expectedDefault.foo.equals('foo'); 
  }

  @test
  public function testConstructorInjecton() {
    var container = new Container();
    container.map(Plain).toType(Plain);
    container.map(InjectsConstructor).toType(InjectsConstructor);
    var expected = container.get(InjectsConstructor).one.value;
    expected.equals('one');
  }

  @test
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

  @test
  public function testParamsInProps() {
    var container = new Container();
    container.map(String).toValue('one');
    container.map(Int).toValue(1);
    container.map('InjectsPropWithParam<String>').toType(InjectsPropWithParam);
    container.map('InjectsPropWithParam<Int>').toType(InjectsPropWithParam);

    container.get('InjectsPropWithParam<String>').foo.equals('one');
    container.get('InjectsPropWithParam<Int>').foo.equals(1);
  }

  @test
  public function testParamsWithVarSyntax() {
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

  @test
  public function testTaggedParams() {
    var container = new Container();
    container.map(String, 'foo').toValue('mapped');
    container.map(var _:HasTaggedParams<String>).toType(HasTaggedParams);
    container.get(var _:HasTaggedParams<String>).foo.equals('mapped');
  }

  @test
  public function testComplexParams() {
    var container = new Container();
    container.map(Int).toValue(2);
    container.map(String).toValue('bar');
    container.map(var _:BaseParams<Int, String>).toType(HasComplexParams);
    var expected = container.get(var _:BaseParams<Int, String>);
    expected.foo.equals(2);
    expected.bar.equals('bar');
  }

  @test('Interfaces are correctly resolved')
  public function testWorksOnInterfaces() {
    var container = new Container();
    container.map(Int).toValue(2);
    container.map(String).toValue('bar');
    container.map(var _:BaseParams<Int, String>).toType(HasComplexParams);
    container.map(var _:UsesBaseParams<Int, String>).toType(CorrectlyFollowsComplexParams);
    var expected = container.get(var _:UsesBaseParams<Int, String>);
    expected.baseParams.foo.equals(2);
    expected.baseParams.bar.equals('bar');
  }

  @test
  public function testDeepParams() {
    var container = new Container();
    container.map('Map<String, String>').toValue([ 'foo' => 'foo' ]);
    container.map('String').toValue('foo');
    container.map(var _:HasDeepParams<String, String>).toType(HasDeepParams);
    var expected = container.get(var _:HasDeepParams<String, String>);
    expected.map.get('foo').equals('foo');
    expected.foo.equals('foo');
  }

  @test
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

  @test
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

  @test
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

  @test
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

  @test
  public function testPostInjection() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.map(PostInject).toType(PostInject);
    var expected = container.get(PostInject);
    expected.ran.equals('foo:one:two:three:four');
  }

  @test
  public function testServiceProvider() {
    var container = new Container();
    container.use(new SimpleServiceProvider());
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
  public function testMappingExtension() {
    var container = new Container();
    container.map(String, 'foo').toValue('foo');
    container.getMapping(String, 'foo').extend(v -> v + 'bar');
    container.get(String, 'foo').equals('foobar');
  }

  @test
  public function testSharedMappingExtension() {
    var container = new Container();
    container.map(Plain).toType(Plain).asShared();
    var p = container.get(Plain);
    p.value.equals('one');
    container.getMapping(Plain).extend(v -> {
      v.value = 'changed';
      v;
    });
    p.value.equals('changed');
  }

  @test
  public function throwsUsefulError() {
    var container = new Container();
    try {
      container.get(String, 'foo');
      Assert.fail('Should have thrown a ContainerError');  
    } catch (e:ContainerError) {
      Assert.pass();
    }
  }

}