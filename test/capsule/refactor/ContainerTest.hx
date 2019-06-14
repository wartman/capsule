package capsule.refactor;

import haxe.ds.Map;
import capsule.refactor.fixture.*;
import fixture.*;
import fixture.params.*;

using medic.Assert;

class ContainerTest {

  public function new() {}

  @test('Mappings can be added directly')
  public function testAdd() {
    var container = new Container();
    container.addMapping(new Mapping(
      new Identifier('String', 'foo'),
      ProvideFactory(c -> 'foo')
    ));
    var mapping:Mapping<String> = container.getMappingByIdentifier(new Identifier('String', 'foo'));
    mapping.getValue(container).equals('foo');
  }

  @test('Mappings can have type params')
  public function testTypeParams() {
    var container = new Container();
    container.map('Array<String>').toValue([ 'a', 'b' ]);
    var values = container.get(var _:Array<String>);
    values.length.equals(2);
    values[0].equals('a');
    values[1].equals('b');
  }

  @test('Mappings can be added via macros')
  public function testMacroMap() {
    var container = new Container();
    
    container.map(String).toValue('bar');
    container.map(String, 'str').toValue('foo');
    container.map(Int, 'one').toValue(1);

    container.get(String, 'str').equals('foo');
    container.get(Int, 'one').equals(1);
    container.get(String).equals('bar');
  }

  @test('Mappings resolve full type paths')
  public function testTypePaths() {
    var container = new Container();

    container.map(Simple).toValue(new Simple('a'));
    container.get(Simple).a.equals('a');
  }

  @test('Mappings resolve full type paths when strings are used')
  public function testStringTypePaths() {
    var container = new Container();

    container.map('Simple').toValue(new Simple('a'));
    container.get('Simple').a.equals('a');
  }

  @test('Mappings resolve full type paths when vars are used')
  public function testVarTypePaths() {
    var container = new Container();

    container.map(var _:Simple).toValue(new Simple('a'));
    container.get(var _:Simple).a.equals('a');
  }

  @test('`Var` can be used to tag mappings')
  public function testAlternateMethodOfTagging() {
    var container = new Container();
    
    container.map(var str:String).toValue('foo');
    container.map(var one:Int).toValue(1);

    container.get(var str:String).equals('foo');
    container.get(var one:Int).equals(1);
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

    container.map('Map<String, String>', 'things').toValue([
      'foo' => 'bar',
      'bar' => 'bin'
    ]);
    var things = container.get('Map<String, String>', 'things');
    things.get('foo').equals('bar');
  }
  @test
  public function testParamsWithVarSyntax() {
    var container = new Container();
    container.map(String).toValue('one');
    container
      .map(var _:HasParams<String>)
      .toClass(HasParams);
    container.map(Int).toValue(1);
    container
      .map(var _:HasParams<Int>)
      .toClass(HasParams);
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
    container.map(var _:HasTaggedParams<String>).toClass(HasTaggedParams);
    container.get(var _:HasTaggedParams<String>).foo.equals('mapped');
  }

  @test
  public function testComplexParams() {
    var container = new Container();
    container.map(Int).toValue(2);
    container.map(String).toValue('bar');
    container.map(var _:BaseParams<Int, String>).toClass(HasComplexParams);
    var expected = container.get(var _:BaseParams<Int, String>);
    expected.foo.equals(2);
    expected.bar.equals('bar');
  }

  @test('Interfaces are correctly resolved')
  public function testWorksOnInterfaces() {
    var container = new Container();
    container.map(Int).toValue(2);
    container.map(String).toValue('bar');
    container.map(var _:BaseParams<Int, String>).toClass(HasComplexParams);
    container.map(var _:UsesBaseParams<Int, String>).toClass(CorrectlyFollowsComplexParams);
    var expected = container.get(var _:UsesBaseParams<Int, String>);
    expected.baseParams.foo.equals(2);
    expected.baseParams.bar.equals('bar');
  }

  @test
  public function testDeepParams() {
    var container = new Container();
    container.map('Map<String, String>').toValue([ 'foo' => 'foo' ]);
    container.map('String').toValue('foo');
    container.map(var _:HasDeepParams<String, String>).toClass(HasDeepParams);
    var expected = container.get(var _:HasDeepParams<String, String>);
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

}
