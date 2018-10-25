package capsule;

class Mapping<T> {

  public var type(default, null):String;
  public var id(default, null):String;
  public var closure:Container;
  private var factory:Container->T;
  private var value:T;
  private var isShared:Bool = false;

  public function new(type:String, ?id:String, ?valueType:T) {
    this.type = type;
    this.id = id;
  }

  public macro function map(ethis:haxe.macro.Expr, type:haxe.macro.Expr, tag:haxe.macro.Expr.ExprOf<String>) {
    return macro @:pos(ethis.pos) ${ethis}.getClosure().map($type, $tag);
  }

  public function getClosure() {
    if (closure == null) closure = new Container();
    return closure;
  }

  public function getValue(container:Container):T {
    if (factory == null) {
      throw 'No factory exists for mapping ${id}';
    }
    if (isShared) {
      if (value == null) value = factory(handleLocalMappings(container)); 
      return value;
    }
    return factory(handleLocalMappings(container));
  }

  public function toFactory(factory:(container:Container)->T) {
    this.factory = factory;
    return this;
  }

  public function toValue(value:T) {
    return toFactory(function (container) return value).asShared();
  }

  public macro function toAlias(ethis:haxe.macro.Expr, type:haxe.macro.Expr) {
    return macro @:pos(ethis.pos) $ethis.toFactory(c -> c.get(${type}));
  }

  public macro function toType(ethis:haxe.macro.Expr, type:haxe.macro.Expr) {
    var mappingType = haxe.macro.Context.typeof(ethis);
    var builder = new capsule.macro.FactoryBuilder(type, mappingType).exportFactory(ethis.pos);
    return macro @:pos(ethis.pos) ${ethis}.toFactory(${builder});
  }

  public function asShared() {
    isShared = true;
    return this;
  }

  private function handleLocalMappings(container:Container):Container {
    if (closure != null) return closure.extend(container);
    return container;
  }

}
