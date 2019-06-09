package capsule.refactor;

enum IdentifierImpl {
  IdType(type:String);
  IdTagged(type:String, tag:String);
}

abstract Identifier(IdentifierImpl) from IdentifierImpl to IdentifierImpl {
  
  public inline function new(type:String, ?tag:String) {
    this = tag == null
      ? IdType(type)
      : IdTagged(type, tag);
  }

  public inline function unbox():IdentifierImpl {
    return this;
  }

  public function toString() {
    return switch unbox() {
      case IdType(type): type;
      case IdTagged(type, tag): '${type}#${tag}';
    }
  }

  @:op(A == B)
  public inline function eq(b:Identifier) {
    return toString() == b.toString();
  }

}
