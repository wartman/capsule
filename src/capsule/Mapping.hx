package capsule;

class Mapping<T> {

  public var type(default, null):String;
  public var id(default, null):String;
  private var factory:Container->T;
  private var value:T;
  private var isShared:Bool = false;

  public function new(type:String, ?id:String) {
    this.type = type;
    this.id = id;
  }

  public function getValue(container:Container):T {
    if (factory == null) {
      throw 'No factory exists for mapping ${id}';
    }
    if (isShared) {
      if (value == null) value = factory(container); 
      return value;
    }
    return factory(container);
  }

  public function toFactory(factory:Container->T) {
    this.factory = factory;
    return this;
  }

  public function toValue(value:T) {
    return toFactory(function (container) return value).asShared();
  }

  // todo: should be `toClass`! And should only be limited to classes.
  public macro function toType(ethis:haxe.macro.Expr, type:haxe.macro.Expr.ExprOf<T>) {
    var builder = new capsule.macro.FactoryBuilder(type).exportFactory(ethis.pos);
    return macro @:pos(ethis.pos) ${ethis}.toFactory(${builder});
  }

  public function asShared() {
    isShared = true;
    return this;
  }

}
