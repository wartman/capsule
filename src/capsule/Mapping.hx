package capsule;

class Mapping<T> {

  public var type(default, null):String;
  public var id(default, null):String;
  public var closure:Container;
  var factory:(Container)->T;
  var value:T;
  var isShared:Bool = false;

  public function new(type:String, ?id:String, ?valueType:T) {
    this.type = type;
    this.id = id;
  }

  public macro function map(ethis:haxe.macro.Expr, type:haxe.macro.Expr, tag:haxe.macro.Expr.ExprOf<String>) {
    return macro @:pos(ethis.pos) ${ethis}.getClosure().map($type, $tag);
  }

  public function with(cb:(closure:Container)->Void) {
    cb(getClosure());
    return this;
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

  public macro function toType(ethis:haxe.macro.Expr, type:haxe.macro.Expr) {
    var mappingType = haxe.macro.Context.typeof(ethis);
    var builder = new capsule.macro.TypeFactoryBuilder(type, mappingType).exportFactory(ethis.pos);
    return macro @:pos(ethis.pos) ${ethis}.__toFactory(${builder});
  }

  public macro function toFactory(ethis, factory) {
    var mappingType = haxe.macro.Context.typeof(ethis);
    var builder = new capsule.macro.FunctionFactoryBuilder(factory).exportFactory();
    return macro @:pos(ethis.pos) ${ethis}.__toFactory(${builder});
  } 

  public function __toFactory(factory:(container:Container)->T) {
    this.factory = factory;
    return this;
  }

  public function toValue(value:T) {
    return __toFactory(_ -> value).asShared();
  }

  public macro function toAlias(ethis:haxe.macro.Expr, type:haxe.macro.Expr) {
    return macro @:pos(ethis.pos) $ethis.__toFactory(c -> c.get(${type}));
  }

  public function asShared() {
    isShared = true;
    return this;
  }

  function handleLocalMappings(container:Container):Container {
    if (closure != null) return closure.extend(container);
    return container;
  }

}
