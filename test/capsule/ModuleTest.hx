package capsule;

import fixture.*;

using medic.Assert;

class ModuleTest {

  public function new() {}
  
  @test
  public function moduleWorks() {
    var container = new Container();
    var module = new TestModule();
    module.register(container);
    container.get(String, 'other-foo').equals('other foo');
  }

  @test
  public function moduleUsesServiceProvider() {
    var container = new Container();
    var module = new TestModule();
    module.register(container);
    container.get(String, 'foo').equals('foo');
  }

  @test
  public function moduleProvidesThings() {
    var container = new Container();
    var module = new TestModule();
    module.register(container);
    container.get(InjectsConstructor).one.value.equals('one');
  }

  @test('Vairables marked `_` with no expression map to types')
  public function moduleRegistersDeps() {
    var container = new Container();
    var module = new TestModule();
    module.register(container);
    container.get(Plain).value.equals('one');
    container.get('HasParams<Plain>').foo.value.equals('one');
  }
  
  @test('Vairables with a name with no expression map to tagged types')
  public function moduleRegistersNammedDeps() {
    var container = new Container();
    var module = new TestModule();
    module.register(container);
    container.get(Plain, 'named').value.equals('one');
  }
  
  @test('Vairables with an expression map to values')
  public function moduleRegistersNammedValues() {
    var container = new Container();
    var module = new TestModule();
    module.register(container);
    container.get(String, 'thing').equals('thing');
  }

}

private class TestModule implements Module {

  @:use var provider:SimpleServiceProvider;

  @:provide var _:Plain;
  @:provide var _:HasParams<Plain>;
  @:provide var named:Plain;
  @:provide var thing:String = 'thing';

  @:provide('other-foo')
  function foo():String {
    return 'other foo';
  }

  // @:provide('foobar')
  // function foobar(@:inject.tag('foo') foo:String) {
  //   return foo + 'bar';
  // }

  @:provide
  function injectsCon(plain:Plain):InjectsConstructor {
    return new InjectsConstructor(plain);
  }

}
