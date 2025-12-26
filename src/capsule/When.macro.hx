package capsule;

import haxe.macro.Context;
import capsule.internal.Builder;
import haxe.macro.Expr;

using haxe.macro.TypeTools;
using capsule.internal.Tools;

class When {
	public static function resolved(self:Expr, transform:Expr):Expr {
		return switch transform.expr {
			case EFunction(kind, f):
				var args = f.args;
				var target = args.shift();

				if (target == null) {
					Context.error('An argument is required', transform.pos);
				}

				if (target.type != null) {
					Context.error('The first argument will point to the value being wrapped. It must not be manually typed.', transform.pos);
				}

				var name = target.name;
				var wrapper:Expr = {
					expr: EFunction(kind, {
						args: args,
						expr: f.expr,
						params: f.params,
						ret: f.ret
					}),
					pos: transform.pos
				};
				var factory = createFactory(wrapper);
				macro @:pos(self.pos) @:privateAccess $self.applyTransform(@:pos(transform.pos) function($name, container) {
					return ${factory}(container);
				});
			default:
				Context.error('Expected a function', transform.pos);
		}
	}

	public static function needs(self:Expr, type:Expr):Expr {
		var t = switch Context.typeof(self) {
			case TInst(_, [t]): t.toComplexType();
			default: macro :Dynamic;
		}
		var v = type.resolveComplexType();
		return macro new capsule.Needs<$t, $v>(@:privateAccess $self.binding);
	}
}
