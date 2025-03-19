package capsule;

typedef MappingInfo = {
	public final id:Identifier;
	public final dependencies:Array<Identifier>;
	public final isDefault:Bool;
	public final isRequired:Bool;
}
