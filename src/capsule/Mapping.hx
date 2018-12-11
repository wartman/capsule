package capsule;

class Mapping<T> {

  public var type(default, null):String;
  public var id(default, null):String;
  public var closure:Container;
  var factory:(container:Container)->T;
  var value:T;
  var isShared:Bool = false;
  var extensions:Array<(value:T)->T> = [];

  public function new(type:String, ?id:String, ?valueType:T) {
    this.type = type;
    this.id = id;
  }

  public function with(cb:(closure:Container)->Void) {
    cb(getClosure());
    return this;
  }

  public function getClosure() {
    if (closure == null) closure = new Container();
    return closure;
  }

  public function extend(ext:(v:T)->T) {
    if (isShared && value != null) {
      value = ext(value);
      return this;
    }
    extensions.push(ext);
    return this;
  }

  public function getValue(container:Container):T {
    if (factory == null) {
      throw 'No factory exists for mapping ${id}';
    }
    if (isShared) {
      if (value == null) value = resolve(container); 
      return value;
    }
    return resolve(container);
  }

  function resolve(container:Container) {
    var c = handleLocalMappings(container);
    var value = factory(c);
    for (ext in extensions) {
      value = ext(value);
    }
    return value;
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
