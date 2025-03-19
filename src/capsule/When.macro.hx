package capsule;

import haxe.macro.Context;
import haxe.macro.Expr;
import capsule.internal.Builder;

using haxe.macro.TypeTools;

class When {
	public static function resolved(self:Expr, transform:Expr):Expr {
		var factory = createFactory(transform, transform.pos);
		return macro @:pos(self.pos) {
			var when = $self;
			var mapping = @:privateAccess when.mapping;
			var provider = @:privateAccess mapping.provider;
			@:privateAccess mapping.provider = new capsule.provider.TransformerProvider(provider, (value, container) -> ${factory}(container));
			when;
		}
	}
}
