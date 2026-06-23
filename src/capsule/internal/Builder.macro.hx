package capsule.internal;

import capsule.internal.ModuleInfo;
import haxe.macro.Context;
import haxe.macro.Expr;

using capsule.internal.Tools;
using haxe.macro.Tools;

function createIdentifier(expr:Expr) {
	return expr.resolveComplexType().complexTypeToIdentifier();
}

function createModuleUser(modules:Array<ExprOf<Module>>) {
	var body = [
		for (m in modules) {
			registerSubModuleWithLocalModule(m.resolveComplexType().complexTypeToIdentifier());
			macro @:privateAccess @:pos(m.pos) container.useModule(container.instantiate(${m}));
		}
	];
	return macro function(container:capsule.Container) {
		@:mergeBlock $b{body};
	}
}

function createProvider(expr:Expr, ret:ComplexType, pos:Position, isDefault:Bool = false):Expr {
	var id = ret.complexTypeToIdentifier();
	switch expr.expr {
		case EFunction(_, _): // continue
		case ECall(e, _):
			switch Context.typeof(e) {
				case TFun(_, _):
					// Is an actual function call (hopefully)
					registerBindingWithLocalModule(id, [], isDefault);
					return macro new capsule.provider.ValueProvider<$ret>(${expr});
				default:
					// Is a generic type -- continue.
			}
		default:
			switch Context.typeof(expr) {
				case TType(_, _) | TFun(_, _): // continue
				default:
					// If not a function or type, default to using a ValueProvider.
					registerBindingWithLocalModule(id, [], isDefault);
					return macro new capsule.provider.ValueProvider<$ret>(${expr});
			}
	}

	var deps = getDependencies(expr, pos);
	var factory = createFactoryWithDeps(deps, expr, pos);

	registerBindingWithLocalModule(id, deps, isDefault);

	return macro new capsule.provider.FactoryProvider<$ret>(${factory});
}

function createFactory(expr:Expr, ?pos:Position) {
	if (pos == null) pos = expr.pos;
	var deps = getDependencies(expr, pos);
	registerDependenciesWithLocalModule(deps);
	return createFactoryWithDeps(deps, expr, pos);
}

private function createFactoryWithDeps(deps:Array<String>, expr:Expr, pos:Position) {
	function createBindingResolver(id:String) {
		return macro bindings.resolve($v{id});
	}

	return switch expr.expr {
		case null:
			macro @:pos(expr.pos) function(bindings:capsule.BindingCollection) return null;
		case EFunction(_, _):
			var args = deps.map(createBindingResolver);
			macro @:pos(expr.pos) function(bindings:capsule.BindingCollection) {
				return ${expr}($a{args});
			}
		case ECall(e, params):
			var expr = getConstructorFromCallExpr(expr, pos);
			createFactoryWithDeps(deps, macro $expr, pos);
		default:
			switch Context.typeof(expr) {
				case TType(_, _):
					var path = expr.toString().split('.');
					checkExprForCorrectTypeParams(expr, pos);
					createFactoryWithDeps(deps, macro $p{path}.new, pos);
				case TFun(args, _):
					var args = deps.map(createBindingResolver);
					macro @:pos(expr.pos) function(bindings:capsule.BindingCollection) {
						var factory = ${expr};
						return factory($a{args});
					};
				default:
					macro @:pos(expr.pos) function(bindings:capsule.BindingCollection) return $expr;
			}
	}
}

function getDependencies(expr:Expr, ?pos:Position):Array<String> {
	if (pos == null) pos = expr.pos;

	return switch expr.expr {
		case null:
			return [];
		case EFunction(_, f):
			return argumentsToIdentifiers(f.args, pos);
		case ECall(e, params):
			return getDependencies(getConstructorFromCallExpr(expr, pos), pos);
		default:
			switch Context.typeof(expr) {
				case TType(_, _):
					var path = expr.toString().split('.');
					checkExprForCorrectTypeParams(expr, pos);
					return getDependencies(macro $p{path}.new, pos);
				case TFun(args, _):
					return args.map(a -> a.t).typesToIdentifiers(pos);
				default:
					return [];
			}
	}
}

function argumentsToIdentifiers(args:Array<FunctionArg>, pos:Position):Array<String> {
	return args.map(a -> a.type.toType()).typesToIdentifiers(pos);
}

private function checkExprForCorrectTypeParams(expr:Expr, pos:Position) {
	switch Context.typeof(expr) {
		case TType(_, _):
			var ct = expr.resolveComplexType();
			// This will throw an error if we don't have the right number of
			// type params, which is all we're looking for.
			Context.resolveType(ct, pos);
		default:
	}
}

private function getConstructorFromCallExpr(expr:Expr, pos:Position):Expr {
	return switch expr.expr {
		case ECall(e, params):
			var ct = expr.resolveComplexType();
			var path = e.toString().split('.');
			var expr = macro $p{path}.new;

			return switch ct.toType() {
				case TInst(t, params):
					var conType = t.get()
						.constructor.get()
						.type.applyTypeParameters(t.get().params, params)
						.toComplexType();
					var t:ComplexType = switch conType {
						case TFunction(args, _): TFunction(args, ct);
						default: throw 'assert';
					}
					macro(${expr} : $t);
				default:
					throw 'assert';
			}
		default:
			throw 'assert';
	}
}
