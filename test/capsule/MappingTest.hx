package capsule;

import fixture.*;

using Medic;
using Type;

class MappingTest implements TestCase {

  public function new() {}

  @test('Classes can be automatically injected')
  public function testToClass() {
    var container = new Container();
    var mapping = new Mapping(new Identifier(Simple.getClassName()));
    
    container.addMapping(new Mapping(
      new Identifier('String'),
      ProvideValue('Ok')
    ));

    mapping
      .toClass(Simple)
      .getValue(container)
      .a.equals('Ok');
  }

  @test('Factory mapping extension')
  public function testMappingExtension() {
    var container = new Container();
    var mapping = new Mapping(
      new Identifier('String', 'foo'),
      Provider.ProvideFactory(c -> 'foo')
    );
    mapping.extend(v -> v + 'bar');
    mapping.getValue(container).equals('foobar');
  }
  
  // todo: test other extensions

}
