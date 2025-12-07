package capsule.internal;

import capsule.Identifier;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;
using haxe.macro.Tools;

typedef ModuleInfo = {
	public final id:String;
	public final exports:Array<MappingInfo>;
	public final dependencies:Array<Identifier>;
	public final uses:Array<Identifier>;
	public final pos:Position;
}

function getModuleInfo(type:Type, pos:Position):ModuleInfo {
	if (!type.unify((macro :capsule.Module).toType())) {
		Context.error('Must be a capsule.Module', pos);
	}

	var mappings:Array<MetadataEntry> = [];
	var requirements:Array<MetadataEntry> = [];
	var subModules:Array<MetadataEntry> = [];
	var exports:Array<MappingInfo> = [];
	var dependencies:Array<Identifier> = [];
	var uses:Array<Identifier> = [];

	function loadMetadata(get:() -> ClassType) {
		var cls = get();
		// Iterate through module fields and ensure types are loaded.
		for (field in cls.fields.get()) {
			field.expr();
		}
		// Reload type to make sure we have any added meta (this feels hacky, but it works?).
		var cls = get();

		mappings = mappings.concat(cls.meta.extract(':capsule.mapping'));
		requirements = requirements.concat(cls.meta.extract(':capsule.dependency'));
		subModules = subModules.concat(cls.meta.extract(':capsule.uses'));

		if (cls.superClass != null) {
			#if !capsule.suppress_module_subclass_warning
			Context.warning(
				'You\'re extending another Module. This is not recommended. It will work, but'
				+ ' may not track dependencies correctly if you override any methods and do not'
				+ ' call `super.{methodName}()`. This is a good way to get runtime errors.'
				+ ' As an alternative, try composing modules with `container.use(...)` instead.'
				+ ' You can suppress this warning with `-D capsule.suppress-module-subclass-warning`.'
				, cls.pos);
			#end
			loadMetadata(() -> cls.superClass.t.get());
		}
	}

	loadMetadata(() -> type.getClass());

	for (mapping in mappings) switch mapping.params {
		case [obj]:
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
		case [arr]:
			switch arr.expr {
				case EArrayDecl(values):
					var deps = values.map(value -> value.getValue());
					for (dep in deps) {
						for (mapping in exports) {
							if (mapping.id != dep && !dependencies.contains(dep)) {
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
		case [id]:
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

function registerMappingWithLocalModule(id:String, dependencies:Array<String>, isDefault:Bool = false) {
	var module = getLocalModule();
	if (module == null) return;
	module.meta.add(':capsule.mapping', [macro {
		id: $v{id},
		dependencies: [$a{dependencies.map(v -> macro $v{v})}],
		isDefault: $v{isDefault}
	}], (macro null).pos);
}

function registerDependenciesWithLocalModule(dependencies:Array<String>) {
	var module = getLocalModule();
	if (module == null) return;
	var param = macro [$a{dependencies.map(v -> macro $v{v})}];
	module.meta.add(':capsule.dependency', [param], (macro null).pos);
}

function registerSubModuleWithLocalModule(id:String) {
	var module = getLocalModule();
	if (module == null) return;
	module.meta.add(':capsule.uses', [macro $v{id}], (macro null).pos);
}
