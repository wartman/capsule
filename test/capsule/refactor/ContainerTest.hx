package capsule.refactor;

import capsule.refactor.fixture.*;
import fixture.*;

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

    // Typing should work here!
    // container.map('Map<String, String>', 'things').toValue([
    //   'foo' => 'bar',
    //   'bar' => 'bin'
    // ]);
    // var things = container.get('Map<String, String>', 'things');
    // things.get('foo').equals('bar');
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

}
