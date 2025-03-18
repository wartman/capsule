package capsule;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using haxe.macro.Tools;
using capsule.internal.Tools;

typedef TrackedMapping = {
	public var ?id:Expr;
	public var ?concrete:Expr;
	public var ?isDefault:Bool;
};

// @todo: Rethink this! We need to track dependencies on `Capsule.extend`.
function build() {
	var isDebug = Context.defined('debug');
	var fields = Context.getBuildFields();
	var cls = Context.getLocalClass().get();
	var provider = fields.find(f -> f.name == 'provide');
	var containerName = 'container';
	var exports:Array<TrackedMapping> = [];
	var imports:Array<TrackedMapping> = [];
	var currentMapping:Null<TrackedMapping> = null;

	if (cls.superClass != null) {
		Context.error('Modules are currently not allowed to extend other classes.', cls.pos);
	}

	if (cls.params.length > 0) {
		Context.error('Modules are currently not allowed to be generic/use type params.', cls.pos);
	}

	if (provider == null) return fields;

	function findMappings(e:Expr, containerName:String) {
		function warn() {
			if (isDebug) {
				Context.warning(
					'Modules can only track dependencies inside a `provide` method '
					+ 'or in an instance method called from `provide`. This appears '
					+ 'to be a call to an external method or function that is being '
					+ 'passed a Container, where dependencies WILL NOT be tracked.',
					e.pos);
			}
		}

		function followMethod(name:String) {
			var field = fields.find(f -> f.name == name);

			if (field == null) {
				warn();
				return;
			}

			switch field.kind {
				case FFun(f):
					var subContainerName = f.args[0].name; // Ensure we have the right identifier.
					findMappings(f.expr, subContainerName);
				default:
			}
		}

		function usesContainer(params:Array<Expr>) {
			for (param in params) switch param.expr {
				case EConst(CIdent(s)) if (s == containerName):
					return true;
				default:
			}
			return false;
		}

		switch e.expr {
			case ECall(e, params):
				switch e.expr {
					case EField(e, 'use'):
						for (param in params) imports.push({id: param, concrete: param});
					case EField(e, 'to') | EField(e, 'toShared'):
						currentMapping = {concrete: params[0]};
						findMappings(e, containerName);
					case EField(e, 'toDefault'):
						currentMapping = {concrete: params[0], isDefault: true};
						findMappings(e, containerName);
					case EField(e, 'map') if (currentMapping != null):
						currentMapping.id = params[0];
						findMappings(e, containerName);
					case EField({expr: EConst(CIdent('this')), pos: _}, field) if (usesContainer(params)):
						followMethod(field);
					case EConst(CIdent(s)) if (usesContainer(params)):
						followMethod(s);
					case _ if (usesContainer(params) && isDebug):
						warn();
					default:
						findMappings(e, containerName);
				}
			case EConst(CIdent(c)) if (c == containerName && currentMapping != null):
				exports.push(currentMapping);
				currentMapping = null;
			default:
				e.iter(e -> findMappings(e, containerName));
		}
	}

	switch provider.kind {
		case FFun(f):
			var expr = f.expr;
			containerName = f.args[0].name; // Ensure we have the right identifier.

			findMappings(expr, containerName);

			// @todo: This is a very weird way to store dependencies, although it
			// does work. Ideally we'd at least put these all on static fields.
			//
			// Unfortunately, due to the use of `Context.typeof(...)` in our macros,
			// this is the only way not to break the compiler.
			fields = fields.concat((macro class {
				@:keep public final __imports:Array<capsule.MappingInfo> = [
					$a{
						imports.map(m -> macro {
							id: capsule.Tools.getIdentifier(${m.id}),
							dependencies: capsule.Tools.getDependencies(${m.concrete}),
							isDefault: $v{m.isDefault == true}
						})
					}
				];
				@:keep public final __exports:Array<capsule.MappingInfo> = [
					$a{
						exports.map(m -> macro {
							id: capsule.Tools.getIdentifier(${m.id}),
							dependencies: capsule.Tools.getDependencies(${m.concrete}),
							isDefault: $v{m.isDefault == true}
						})
					}
				];
			}).fields);
		default:
	}

	return fields;
}
