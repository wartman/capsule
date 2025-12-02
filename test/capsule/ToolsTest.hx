package capsule;

import fixture.*;
import utest.*;

using capsule.Tools;
using utest.Assert;

class ToolsTest extends Test {
	function testSimpleTools() {
		var container = new Container().withTransient(String, 'foo');

		container.withTransient(ValueService, Value).withSingleton(SimpleService, SimpleWithDep);

		var a = container.get(ValueService);
		var b = container.get(ValueService);

		(a == b).isFalse();

		var a = container.get(SimpleService);
		var b = container.get(SimpleService);

		(a == b).isTrue();

		container.get(SimpleService).getValue().equals('foo');
	}

	function testDeps() {
		var deps = Tools.getDependencies(SimpleWithDep);
		deps.length.equals(1);
		deps[0].equals('fixture.ValueService');
	}
}
