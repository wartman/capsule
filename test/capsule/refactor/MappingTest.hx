package capsule.refactor;

import capsule.refactor.fixture.*;

using medic.Assert;
using Type;

class MappingTest {

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

}
