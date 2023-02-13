package capsule;

import haxe.macro.Expr;
import capsule.internal.Builder;

class Container {
	public static function build(...modules:ExprOf<Module>) {
		return ContainerBuilder.buildFromModules(modules.toArray());
	}

	public static function map(self:Expr, target:Expr) {
		var identifier = createIdentifier(target);
		var type = getComplexType(target);
		return macro @:pos(self.pos) @:privateAccess ($self.ensureMapping($v{identifier}) : capsule.Mapping<$type>);
	}

	public static function get(self:Expr, target:Expr) {
		var identifier = createIdentifier(target);
		var type = getComplexType(target);
		return macro @:pos(target.pos) ($self.ensureMapping($v{identifier}) : capsule.Mapping<$type>).resolve();
	}

	public static function getMapping(self:Expr, target:Expr) {
		var identifier = createIdentifier(target);
		var type = getComplexType(target);
		return macro @:pos(target.pos) ($self.ensureMapping($v{identifier}) : capsule.Mapping<$type>);
	}

	public static function instantiate(self:Expr, target:Expr) {
		var factory = createFactory(target, target.pos);
		return macro @:pos(target.pos) ${factory}($self);
	}

	public static function use(self:Expr, ...modules:ExprOf<Module>) {
		var body = [
			for (m in modules) macro @:privateAccess $self.useModule($self.instantiate(${m}))
		];
		return macro @:pos(self.pos) $b{body};
	}
}
