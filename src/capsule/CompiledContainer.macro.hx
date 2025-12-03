package capsule;

import haxe.macro.Context;
import haxe.macro.Expr;

using capsule.internal.Builder;
using haxe.macro.Tools;

class CompiledContainerBase {
	macro public static function open(self, handler):Expr {
		var type = Context.typeof(self);
		var cls = type.getClass();

		var provides = switch cls.meta.extract(':capsule.provides') {
			case [entry]:
				switch entry.params {
					case [expr]:
						switch expr.expr {
							case EConst(CString(s, _)):
								s.split(';');
							default:
								Context.error('Expected a string', expr.pos);
						}
					case []:
						[];
					case params:
						Context.error('Too many params', params[params.length - 1].pos);
				}
			default:
				Context.error('Completion failed -- try restarting the Haxe server.', self.pos);
		}

		var deps = handler.getDependencies();
		for (dep in deps) {
			if (!provides.contains(dep)) {
				Context.error('Container requires $dep.', handler.pos);
			}
		}

		var factory = handler.createFactory();
		return macro @:pos(handler.pos) ${factory}(@:privateAccess $self.container);
	}
}
