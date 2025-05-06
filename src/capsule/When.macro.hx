package capsule;

import capsule.internal.Builder;
import haxe.macro.Expr;

using haxe.macro.TypeTools;

class When {
	public static function resolved(self:Expr, transform:Expr):Expr {
		var factory = createFactory(transform, transform.pos);
		return macro @:privateAccess @:pos(self.pos) $self.applyTransform(@:pos(transform.pos) function(value, container) {
			return ${factory}(container);
		});
	}
}
