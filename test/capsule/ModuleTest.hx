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

  @test('Providers can be shared')
  public function providersCanBeShared() {
    var container = new Container();
    var module = new TestModule();
    module.register(container);
    var data = container.get('Array<String>');
    data[0].equals('foo');
    data.push('bar');
    var beta = container.get('Array<String>');
    beta.length.equals(2);
    beta[1].equals('bar');
  }

  @test('Providers can have tagged args')
  public function providerHasTaggedArg() {
    var container = new Container();
    var module = new TestModule();
    module.register(container);
    var foobar = container.get(String, 'foobar');
    foobar.equals('other foobar');
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

  @:provide('foobar')
  function foobar(@:inject.tag('other-foo') foo:String):String {
    return foo + 'bar';
  }

  @:provide
  function injectsCon(plain:Plain):InjectsConstructor {
    return new InjectsConstructor(plain);
  }

  @:provide
  @:share
  function shared():Array<String> {
    return [ 'foo' ];
  }

}
