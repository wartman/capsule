package capsule;

import capsule.internal.ModuleInfo;
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using capsule.internal.Builder;
using capsule.internal.Tools;
using haxe.crypto.Md5;
using haxe.macro.Tools;

class Container {
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

	public static function compile(...exprs:ExprOf<Module>) {
		var values = exprs.toArray();
		var modules = values.map(e -> {
			var type = Context.typeof(e);
			return getModuleInfo(type, e.pos);
		});
		var rootModules = modules.copy();
		var body:Array<Expr> = values.map(module -> macro $module.provide(container));
		var provided:Array<String> = [];
		var defaults:Array<String> = [];

		function scanSubModules(module:ModuleInfo, pos:Position) {
			for (child in module.uses) {
				if (modules.exists(m -> m.id == child)) {
					Context.error('The module [${child}] was already added.', pos);
				}

				var type = Context.getType(child);
				var info = getModuleInfo(type, pos);

				modules.push(info);

				scanSubModules(info, pos);
			}
		}

		for (module in rootModules) scanSubModules(module, module.pos);
		for (module in modules) for (export in module.exports) {
			if (provided.contains(export.id)) {
				if (defaults.contains(export.id)) {
					defaults.remove(export.id);
					continue;
				}
				if (export.isDefault) {
					continue;
				}
				Context.error('${export.id} was already provided', module.pos);
			} else {
				if (export.isDefault) defaults.push(export.id);
				provided.push(export.id);
			}
		}
		for (module in modules) {
			for (export in module.exports) for (dependency in export.dependencies) {
				if (!provided.contains(dependency)) {
					Context.error('The binding ${export.id} requires ${dependency}', module.pos);
				}
			}
			for (dependency in module.dependencies) {
				if (!provided.contains(dependency)) {
					Context.error('The module ${module.id} requires ${dependency}', module.pos);
				}
			}
		}

		provided.sort((a, b) -> if (a > b) 1 else -1);

		var id = provided.join('_').encode();

		var path:TypePath = {
			pack: ['capsule', 'compiled'],
			name: 'CompiledContainer_$id'
		};

		try {
			var type:ComplexType = TPath(path);
			// @todo: Is there a better way to check this?
			// If this does not throw the type already exists:
			type.toType();
		} catch (_) {
			Context.defineType({
				name: path.name,
				pack: path.pack,
				pos: (macro null).pos,
				meta: [
					{
						name: ':capsule.provides',
						params: [macro [$a{provided.map(p -> macro $v{p})}]],
						pos: (macro null).pos
					}
				],
				kind: TDClass({
					name: 'CompiledContainer',
					pack: ['capsule']
				}),
				fields: []
			});
		}

		return macro {
			var container = new capsule.Container();
			@:mergeBlock $b{body};
			new $path(container);
		}
	}
}
