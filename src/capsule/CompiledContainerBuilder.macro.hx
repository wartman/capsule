package capsule;

import capsule.internal.ModuleInfo;
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using capsule.internal.Tools;
using haxe.crypto.Md5;
using haxe.macro.Tools;

function buildGeneric() {
	return switch Context.getLocalType() {
		case TInst(_, [TInst(_.get() => {kind: KExpr({expr: EArrayDecl(parts), pos: _})}, _)]):
			buildContainer(parts.map(part -> switch part.expr {
				case EConst(CString(s, _)): s;
				default: null;
			}).filter(n -> n != null));
		default:
			throw 'assert';
	}
}

function buildContainer(provides:Array<String>) {
	var id = provides.join('_').encode();
	var path:TypePath = {
		name: 'Container_$id',
		pack: ['capsule', 'compiled']
	};
	var type:ComplexType = TPath(path);

	try {
		type.toType();
		// If this does not throw, the type already exists.
		return type;
	} catch (_) {}

	Context.defineType({
		name: path.name,
		pack: path.pack,
		pos: (macro null).pos,
		meta: [
			{
				name: ':capsule.provides',
				params: [
					macro [$a{provides.map(s -> macro $v{s})}]
				],
				pos: (macro null).pos
			}
		],
		kind: TDClass({
			name: 'CompiledContainer',
			sub: 'CompiledContainerBase',
			pack: ['capsule']
		}),
		fields: []
	});

	return type;
}

function createCompiledContainer(values:Array<ExprOf<Module>>):Expr {
	var modules = values.map(e -> {
		var type = Context.typeof(e);
		return getModuleInfo(type, e.pos);
	});
	var rootModules = modules.copy();
	var body:Array<Expr> = values.map(module -> macro $module.provide(container));
	var satisfied:Array<String> = [];
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
		if (satisfied.contains(export.id)) {
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
			satisfied.push(export.id);
		}
	}
	for (module in modules) {
		for (export in module.exports) for (dependency in export.dependencies) {
			if (!satisfied.contains(dependency)) {
				Context.error('The binding ${export.id} requires ${dependency}', module.pos);
			}
		}
		for (dependency in module.dependencies) {
			if (!satisfied.contains(dependency)) {
				Context.error('The module ${module.id} requires ${dependency}', module.pos);
			}
		}
	}

	satisfied.sort((a, b) -> if (a > b) 1 else -1);

	var path:TypePath = {
		pack: ['capsule'],
		name: 'CompiledContainer',
		params: [TPExpr(macro [$a{satisfied.map(s -> macro $v{s})}])]
	};

	return macro {
		var container = new capsule.Container();
		@:mergeBlock $b{body};
		new $path(container);
	}
}
