package capsule.refactor;

abstract Identifier(String) {
  
  public inline function new(type:String, ?tag:String) {
    this = tag == null ? type : '${type}#${tag}';
  }

  @:to public inline function toString():String {
    return this;
  }

  @:op(A == B)
  public inline function eq(b:Identifier) {
    return toString() == b.toString();
  }

}
