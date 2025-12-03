package capsule;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;
using capsule.internal.Tools;
using haxe.crypto.Md5;
using haxe.macro.Tools;

function buildGeneric() {
	return switch Context.getLocalType() {
		case TInst(_, [TInst(_.get() => {kind: KExpr({expr: EConst(CString(s, _)), pos: _})}, _)]):
			buildContainer(s);
		default:
			throw 'assert';
	}
}

function buildContainer(provides:String) {
	var id = provides.encode();
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
					macro $v{provides}
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
	var modules = values.map(parseModuleExpr);
	var rootModules = modules.copy();
	var body:Array<Expr> = values.map(module -> macro $module.provide(container));
	var satisfied:Array<String> = [];
	var defaults:Array<String> = [];

	for (module in rootModules) processModule(module, modules, module.pos);
	for (module in modules) for (export in module.exports) {
		if (satisfied.contains(export.id)) {
			if (defaults.contains(export.id)) {
				defaults.remove(export.id);
				continue;
			}
			if (export.isDefault || export.isRequired) {
				continue;
			}
			Context.error('${export.id} was already provided', module.pos);
		} else {
			if (export.isDefault) defaults.push(export.id);
			if (export.isRequired) continue;
			satisfied.push(export.id);
		}
	}
	for (module in modules) {
		for (export in module.exports) for (dependency in export.dependencies) {
			if (!satisfied.contains(dependency)) {
				Context.error('The mapping ${export.id} requires ${dependency}', module.pos);
			}
		}
		for (child in module.imports) for (dependency in child.dependencies) {
			if (!satisfied.contains(dependency)) {
				Context.error('The module ${child.id} requires ${dependency}', module.pos);
			}
		}
	}

	satisfied.sort((a, b) -> if (a > b) 1 else -1);

	var provides = satisfied.join(';');
	var path:TypePath = {
		pack: ['capsule'],
		name: 'CompiledContainer',
		params: [TPExpr(macro $v{provides})]
	};

	return macro {
		var container = new capsule.Container();
		@:mergeBlock $b{body};
		new $path(container);
	}
}

private function processModule(module:ModuleInfo, modules:Array<ModuleInfo>, pos:Position) {
	for (child in module.imports) {
		if (modules.exists(m -> m.id == child.id)) {
			Context.error('The module [${child.id}] was already added.', pos);
		}

		var type = Context.getType(child.id);
		var info = parseModuleInfo(type, pos);

		modules.push(info);

		processModule(info, modules, pos);
	}
}

private function parseModuleExpr(e:ExprOf<Module>):ModuleInfo {
	var type = Context.typeof(e);
	return parseModuleInfo(type, e.pos);
}

private function parseModuleInfo(type:Type, pos:Position):ModuleInfo {
	if (!Context.unify(type, Context.getType('capsule.Module'))) {
		Context.error('${type.toString()} should be capsule.Module', pos);
	}

	var exports = parseModuleMappings(type, '__exports');
	var imports = parseModuleMappings(type, '__imports');

	return {
		id: type.toComplexType().toString(),
		exports: exports,
		imports: imports,
		pos: pos
	};
}

private function parseModuleMappings(type:Type, field:String):Array<MappingInfo> {
	return switch type {
		case TInst(t, params):
			var cls = t.get();
			var exports = cls.findField(field, false).expr();
			var out:Array<MappingInfo> = [];

			switch exports.expr {
				case TArrayDecl(el): for (expr in el) {
						out.push(exprToModuleMapping(expr));
					}
				default: throw 'assert';
			}

			out;
		default:
			[];
	}
}

private function exprToModuleMapping(expr:TypedExpr):MappingInfo {
	return switch expr.expr {
		case TObjectDecl(fields):
			var id = fields.find(f -> f.name == 'id').expr;
			var deps = fields.find(f -> f.name == 'dependencies').expr;
			var isDef = fields.find(f -> f.name == 'isDefault').expr;
			var isRequired = fields.find(f -> f.name == 'isRequired').expr;
			return {
				id: id.exprToString(),
				dependencies: deps.exprToArray(),
				isDefault: isDef.exprToBool(),
				isRequired: isRequired.exprToBool()
			};
		default:
			throw 'assert';
	}
}
