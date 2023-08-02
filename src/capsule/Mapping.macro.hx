package capsule;

import haxe.macro.Context;
import haxe.macro.Expr;
import capsule.internal.Builder;

using haxe.macro.TypeTools;

class Mapping {
	public static function to(self:Expr, factory:Expr) {
		var t = switch Context.typeof(self) {
			case TInst(_, [t]): t.toComplexType();
			default: macro :Dynamic;
		}
		var provider = createProvider(factory, t, factory.pos);
		return macro @:pos(self.pos) $self.toProvider($provider);
	}

	public static function toShared(self, factory) {
		return macro @:pos(self.pos) $self.to($factory).share();
	}

	public static function toDefault(self, factory) {
		var t = switch Context.typeof(self) {
			case TInst(_, [t]): t.toComplexType();
			default: macro :Dynamic;
		}
		var provider = createProvider(factory, t, factory.pos);
		return macro @:pos(self.pos) {
			var mapping = $self;
			if (!mapping.resolvable()) {
				mapping.toProvider(new capsule.provider.OverridableProvider($provider));
			}
			mapping;
		}
	}
}
