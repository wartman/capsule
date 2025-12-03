package capsule;

import haxe.macro.Context;
import haxe.macro.Expr;

using capsule.internal.Builder;
using haxe.macro.Tools;

class CompiledContainerBase {
	macro public static function open(self, handler):Expr {
		var type = Context.typeof(self);
		var cls = type.getClass();
		var providesField = cls.findField('__provides', true).expr();

		var provides = switch providesField?.expr {
			case null:
				Context.error('Container was not compiled correctly.', handler.pos);
				[];
			case TArrayDecl(fields):
				[
					for (item in fields) switch item.expr {
						case TConst(TString(s)):
							s;
						default:
							Context.error('Expected a string', item.pos);
							'';
					}
				];
			default:
				Context.error('Invalid type', providesField.pos);
				[];
		}

		var deps = handler.getDependencies();
		for (dep in deps) {
			if (!provides.contains(dep)) {
				Context.error('Container does not have a mapping for $dep.', handler.pos);
			}
		}

		var factory = handler.createFactory();
		return macro @:pos(handler.pos) ${factory}(@:privateAccess $self.container);
	}
}
