package capsule.internal;

import capsule.Identifier;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;
using haxe.macro.Tools;

typedef ModuleInfo = {
	public final id:String;
	public final exports:Array<BindingInfo>;
	public final dependencies:Array<Identifier>;
	public final uses:Array<Identifier>;
	public final pos:Position;
}

function getModuleInfo(type:Type, pos:Position):ModuleInfo {
	if (!type.unify((macro :capsule.Module).toType())) {
		Context.error('Must be a capsule.Module', pos);
	}

	var cls = type.getClass();
	var bindings:Array<MetadataEntry> = [];
	var requirements:Array<MetadataEntry> = [];
	var subModules:Array<MetadataEntry> = [];
	var visitedMethods:Array<String> = [];
	var exports:Array<BindingInfo> = [];
	var dependencies:Array<Identifier> = [];
	var uses:Array<Identifier> = [];

	function usesContainer(id:Int, args:Array<TypedExpr>) {
		for (arg in args) switch arg.expr {
			case TLocal(v) if (v.id == id):
				return true;
			default:
		}
		return false;
	}

	function visitMethod(cls:ClassType, field:Null<ClassField>) {
		function scanMethodsThatUseContainer(id:Int, expr:TypedExpr) {
			switch expr?.expr {
				case TCall(e, args) if (usesContainer(id, args)):
					switch e?.expr {
						case TField(e, FInstance(_.get() => c, params, _.get() => field)):
							visitMethod(c, field);
						default:
					}
				default:
					expr?.iter(e -> scanMethodsThatUseContainer(id, e));
			}
		}

		if (field == null) return;
		switch field.kind {
			case FMethod(_):
				switch field.expr()?.expr {
					case TFunction(f):
						var container = f.args.find(f -> f.v.t.unify((macro :capsule.Container).toType()));
						if (container == null) return;

						var id = formatMethodId(cls, field.name);
						if (!visitedMethods.contains(id)) visitedMethods.push(id);
						scanMethodsThatUseContainer(container.v.id, f.expr);
					default:
				}
			default:
		}
	}

	visitMethod(cls, cls.findField('provide', false));

	function loadMetadata(get:() -> ClassType) {
		var cls = get();
		bindings = bindings.concat(cls.meta.extract(':capsule.binding'));
		requirements = requirements.concat(cls.meta.extract(':capsule.dependency'));
		subModules = subModules.concat(cls.meta.extract(':capsule.uses'));

		if (cls.superClass != null) {
			loadMetadata(() -> cls.superClass.t.get());
		}
	}

	loadMetadata(() -> type.getClass());

	for (binding in bindings) switch binding.params {
		case [method, obj] if (visitedMethods.contains(method.getValue())):
			switch obj.expr {
				case EObjectDecl(fields):
					exports.push({
						id: fields.find(item -> item.field == 'id').expr.getValue(),
						dependencies: switch fields.find(item -> item.field == 'dependencies')?.expr?.expr {
							case EArrayDecl(values):
								values.map(value -> value.getValue());
							default:
								[];
						},
						isDefault: fields.find(item -> item.field == 'isDefault')?.expr?.getValue() == true
					});
				default:
			}
		default:
	}

	for (item in requirements) switch item.params {
		case [method, arr] if (visitedMethods.contains(method.getValue())):
			switch arr.expr {
				case EArrayDecl(values):
					var deps = values.map(value -> value.getValue());
					for (dep in deps) {
						for (binding in exports) {
							if (binding.id != dep && !dependencies.contains(dep)) {
								dependencies.push(dep);
								break;
							}
						}
					}
				default:
			}
		default:
	}

	for (module in subModules) switch module.params {
		case [method, id] if (visitedMethods.contains(method.getValue())):
			switch id.expr {
				case EConst(CString(s, _)):
					uses.push(s);
				default:
			}
		default:
	}

	return {
		id: type.toString(),
		pos: pos,
		exports: exports,
		dependencies: dependencies,
		uses: uses
	}
}

function getLocalModule():Null<ClassType> {
	var type = Context.getLocalType();
	if (type == null) return null;
	if (!type.unify((macro :capsule.Module).toType())) {
		return null;
	}
	return type.getClass();
}

private function formatMethodId(module:ClassType, name:String) {
	var moduleId = module.module + ';' + module.pack.concat([module.name]).join('.');
	return moduleId + '|' + name;
}

private function getQualifiedLocalMethod(module:ClassType) {
	return formatMethodId(module, Context.getLocalMethod());
}

function registerBindingWithLocalModule(id:String, dependencies:Array<String>, isDefault:Bool = false) {
	var module = getLocalModule();
	if (module == null) return;
	var method = getQualifiedLocalMethod(module);
	module.meta.add(':capsule.binding', [macro $v{method}, macro {
		id: $v{id},
		dependencies: [$a{dependencies.map(v -> macro $v{v})}],
		isDefault: $v{isDefault}
	}], (macro null).pos);
}

function registerDependenciesWithLocalModule(dependencies:Array<String>) {
	var module = getLocalModule();
	if (module == null) return;
	var method = getQualifiedLocalMethod(module);
	var param = macro [$a{dependencies.map(v -> macro $v{v})}];
	module.meta.add(':capsule.dependency', [macro $v{method}, param], (macro null).pos);
}

function registerSubModuleWithLocalModule(id:String) {
	var module = getLocalModule();
	if (module == null) return;
	var method = getQualifiedLocalMethod(module);
	module.meta.add(':capsule.uses', [macro $v{method}, macro $v{id}], (macro null).pos);
}
