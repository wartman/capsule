package capsule;

import haxe.macro.Context;
import haxe.macro.Expr;

using capsule.internal.Builder;
using capsule.internal.Tools;
using haxe.macro.Tools;

class CompiledContainer {
	public static function open(self:Expr, handler:Expr):Expr {
		var provides = getProvidedTypes(self);
		var deps = handler.getDependencies();

		for (dep in deps) {
			if (!provides.contains(dep)) {
				Context.error('Container does not provide $dep.', handler.pos);
			}
		}

		var factory = handler.createFactory();
		return macro @:pos(handler.pos) ${factory}(@:privateAccess $self.container);
	}

	public static function get(self:Expr, target:Expr):Expr {
		var provides = getProvidedTypes(self);
		var id = target.createIdentifier();
		var type = target.resolveComplexType();

		if (!provides.contains(id)) {
			Context.error('Container does not provide $id.', target.pos);
		}

		return macro @:pos(target.pos) @:privateAccess ($self.container.resolveBoundValue($v{id}) : $type);
	}

	static function getProvidedTypes(self:Expr) {
		var type = Context.typeof(self);
		var cls = type.getClass();
		return switch cls.meta.extract(':capsule.provides') {
			case [entry]:
				switch entry.params {
					case [expr]:
						switch expr.expr {
							case EArrayDecl(values):
								values.map(value -> switch value.expr {
									case EConst(CString(s, _)): s;
									default: null;
								}).filter(s -> s != null);
							default:
								Context.error('Expected an array', expr.pos);
						}
					case []:
						[];
					case params:
						Context.error('Too many params', params[params.length - 1].pos);
				}
			default:
				Context.error('Completion failed -- try restarting the Haxe server.', self.pos);
		}
	}
}
