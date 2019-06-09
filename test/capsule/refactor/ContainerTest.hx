package capsule.refactor;

using medic.Assert;

class ContainerTest {

  public function new() {}

  @test('Mappings can be added directly')
  public function testAdd() {
    var container = new Container();
    container.addMapping(new Mapping(
      new Identifier('String', 'foo'),
      new Provider(c -> 'foo')
    ));
    var mapping:Mapping<String> = container.getMappingByIdentifier(new Identifier('String', 'foo'));
    mapping.getValue(container).equals('foo');
  }

  @test('Mappings can be added during runtime')
  public function testRuntimeMap() {
    var container = new Container();
    container.mapIdentifier(new Identifier('String', 'foo')).toValue('foo');
    var expected:String = container.getValueByIdentifier(new Identifier('String', 'foo'));
    expected.equals('foo');
  }

  @test('Mappings can be added via macros')
  public function testMacroMap() {
    var container = new Container();
    container.map(String, 'str').toValue('foo');
    container.map(Int, 'one').toValue(1);

    container.get(String, 'str').equals('foo');
    container.get(Int, 'one').equals(1);
  }

  @test('`Var` can be used to tag mappings')
  public function testAlternateMethodOfTagging() {
    var container = new Container();
    container.map(var str:String).toValue('foo');
    container.map(var one:Int).toValue(1);

    container.get(var str:String).equals('foo');
    container.get(var one:Int).equals(1);
  }

}
