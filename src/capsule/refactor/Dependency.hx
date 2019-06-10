package capsule.refactor;

abstract Dependency<T>(Identifier) to Identifier from Identifier {
  
  public inline function new(type:String, ?tag:String) {
    this = new Identifier(type, tag);
  }

}
