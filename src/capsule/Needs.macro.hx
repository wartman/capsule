package capsule;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
using capsule.internal.Builder;
using capsule.internal.Tools;

class Needs {
	public static function give(self:Expr, expr:Expr):Expr {
		var t = switch Context.typeof(self) {
			case TInst(_, [t, v]): v.toComplexType();
			default: macro :Dynamic;
		}
		var id = t.complexTypeToIdentifier();
		var factory = expr.createFactory();
		return macro @:pos(self.pos) @:privateAccess $self.applyNeedsBinding($v{id}, $factory);
	}
}
