package capsule;

import haxe.macro.Expr;

using capsule.internal.Builder;
using capsule.internal.Tools;

class Container {
	public static function compile(...modules:ExprOf<Module>) {
		return CompiledContainerBuilder.createCompiledContainer(modules);
	}

	@:deprecated('Use `bind` instead')
	public static function map(self:Expr, target:Expr) {
		haxe.macro.Context.warning('Use `bind` instead', haxe.macro.Context.currentPos());
		return bind(self, target);
	}

	public static function bind(self:Expr, target:Expr) {
		var identifier = target.createIdentifier();
		var type = target.resolveComplexType();
		return macro @:pos(self.pos) @:privateAccess ($self.ensureBinding($v{identifier}) : capsule.Binding<$type>);
	}

	public static function get(self:Expr, target:Expr) {
		var identifier = target.createIdentifier();
		var type = target.resolveComplexType();
		return macro @:pos(target.pos) ($self.resolveBoundValue($v{identifier}) : $type);
	}

	public static function when(self:Expr, target:Expr) {
		var identifier = target.createIdentifier();
		var type = target.resolveComplexType();
		return macro new capsule.When<$type>(@:privateAccess $self.ensureBinding($v{identifier}));
	}

	public static function instantiate(self:Expr, target:Expr) {
		var factory = target.createFactory();
		return macro @:pos(target.pos) ${factory}($self);
	}

	public static function use(self:Expr, ...modules:ExprOf<Module>) {
		var factory = modules.toArray().createModuleUser();
		return macro ${factory}($self);
	}
}
