package capsule;

import haxe.macro.Expr;

typedef ModuleInfo = {
	public final id:String;
	public final exports:Array<MappingInfo>;
	public final imports:Array<MappingInfo>;
	public final pos:Position;
}
