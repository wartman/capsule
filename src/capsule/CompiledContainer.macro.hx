package capsule;

import capsule.CompiledContainerBuilder.compiledContainerProviders;
import haxe.macro.Context;
import haxe.macro.Expr;

using capsule.internal.Builder;
using haxe.macro.Tools;

class CompiledContainerBase {
	macro public static function open(self, handler):Expr {
		var type = Context.typeof(self);
		var cls = type.getClass();
		var provides = compiledContainerProviders.get(cls.name);

		if (provides == null) {
			Context.error('Could not locate providers for this container', self.pos);
		}

		// var provides = switch providesField?.expr {
		// 	case null:
		// 		Context.error('Invalid type', self.pos);
		// 		[];
		// 	case TArrayDecl(fields):
		// 		[
		// 			for (item in fields) switch item.expr {
		// 				case TConst(TString(s)):
		// 					s;
		// 				default:
		// 					Context.error('Expected a string', item.pos);
		// 					'';
		// 			}
		// 		];
		// 	default:
		// 		Context.error('Invalid type', providesField.pos);
		// 		[];
		// }

		var deps = handler.getDependencies();
		for (dep in deps) {
			if (!provides.contains(dep)) {
				Context.error('The dependency $dep is not available from this container', handler.pos);
			}
		}

		var factory = handler.createFactory();
		return macro @:pos(handler.pos) ${factory}(@:privateAccess $self.container);
	}
}
