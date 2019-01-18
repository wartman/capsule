package capsule;

import fixture.*;

using hex.unittest.assertion.Assert;

class ModuleTest {

  @Test
  public function moduleWorks() {
    var container = new Container();
    var module = new TestModule();
    module.register(container);
    container.get(String, 'other-foo').equals('other foo');
  }

  @Test
  public function moduleUsesServiceProvider() {
    var container = new Container();
    var module = new TestModule();
    module.register(container);
    container.get(String, 'foo').equals('foo');
  }

  @Test
  public function moduleProvidesThings() {
    var container = new Container();
    var module = new TestModule();
    module.register(container);
    container.get(InjectsConstructor).one.value.equals('one');
  }

}

private class TestModule implements Module {

  @:use var provider:SimpleServiceProvider;

  @:provide('other-foo')
  function foo():String {
    return 'other foo';
  }

  // @:provide('foobar')
  // function foobar(@:inject.tag('foo') foo:String) {
  //   return foo + 'bar';
  // }

  @:provide
  function plain():Plain {
    return new Plain();
  }

  @:provide
  function injectsCon(plain:Plain):InjectsConstructor {
    return new InjectsConstructor(plain);
  }

}
