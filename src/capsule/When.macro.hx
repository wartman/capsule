package capsule;

import haxe.macro.Context;
import haxe.macro.Expr;
import capsule.internal.Builder;

using haxe.macro.TypeTools;

class When {
	public static function resolved(self:Expr, transform:Expr):Expr {
		var factory = createFactory(transform, transform.pos);
		var t = switch Context.typeof(self) {
			case TInst(_, [t]): t.toComplexType();
			default: macro :Dynamic;
		}
		return macro @:privateAccess @:pos(self.pos) $self.applyTransform(@:pos(transform.pos) function(value, container) {
			return ${factory}(container);
		});
	}
}
