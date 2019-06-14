package capsule.refactor;

using StringTools;

abstract Identifier(String) {
  
  public inline function new(type:String, ?tag:String) {
    this = tag == null ? type : '${type}#${tag}';
  }

  public inline function hasTag():Bool {
    return this.contains('#');
  }

  public function getTag():String {
    if (!hasTag()) {
      return '';
    }
    return this.substr(this.indexOf('#') + 1);
  }

  public function getType():String {
    if (!hasTag()) {
      return this;
    }
    return this.substring(0, this.indexOf('#'));
  }

  public inline function withoutTag() {
    return new Identifier(getType());
  }

  public inline function withTag(tag:String) {
    return new Identifier(getType(), tag);
  }

  @:to public inline function toString():String {
    return this;
  }

  @:op(a == b)
  public inline function eq(b:Identifier) {
    return toString() == b.toString();
  }

}
