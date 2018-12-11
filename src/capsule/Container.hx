package capsule;

class Container {

  var parent:Container;
  var mappings:Map<String, Mapping<Dynamic>> = new Map();

  public function new(?parent:Container, ?mappings:Map<String, Mapping<Dynamic>>) {
    this.parent = parent;
    if (mappings != null) this.mappings = mappings;
    __map('capsule.Container').toValue(this);
  }

  public function getChild() {
    return new Container(this);
  }

  public function extend(container:Container) {
    return new Container(container, mappings);
  }

  public function use(serviceProvider:ServiceProvider) {
    serviceProvider.register(this);
    return this;
  }

  public macro function getMapping(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var key = capsule.macro.MappingBuilder.getMappingKey(def);
    var type = capsule.macro.MappingBuilder.getMappingType(def);
    var possibleTag = capsule.macro.MappingBuilder.extractMappingTag(def);
    if (possibleTag != null) tag = possibleTag;
    return macro @:pos(ethis.pos) $ethis.__getMapping($key, $tag, (null:$type));
  }

  public function __getMapping<T>(key:String, ?tag:String, ?value:T):Mapping<T> {
    var name = getMappingKey(key, tag);
    var mapping:Mapping<T> = cast mappings.get(name);
    if (mapping == null) {
      if (parent != null) return parent.__getMapping(key, tag, value);
      throw 'No mapping was found for ${name}';
    }
    return mapping;
  }

  public macro function map(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var key = capsule.macro.MappingBuilder.getMappingKey(def);
    var type = capsule.macro.MappingBuilder.getMappingType(def);
    var possibleTag = capsule.macro.MappingBuilder.extractMappingTag(def);
    if (possibleTag != null) tag = possibleTag;
    return macro @:pos(ethis.pos) $ethis.__map($key, $tag, (null:$type));
  }

  public function __map<T>(key:String, ?tag:String, ?value:T):Mapping<T> {
    var name = getMappingKey(key, tag);
    if (mappings.exists(name)) return cast mappings.get(name);
    var mapping = new Mapping(key, tag, value);
    mappings.set(name, mapping);
    return mapping;
  }

  public macro function get(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var key = capsule.macro.MappingBuilder.getMappingKey(def);
    var type = capsule.macro.MappingBuilder.getMappingType(def);
    var possibleTag = capsule.macro.MappingBuilder.extractMappingTag(def);
    if (possibleTag != null) tag = possibleTag;
    return macro @:pos(ethis.pos) ($ethis.__get($key, $tag):$type);
  }

  public function __get<T>(key:String, ?tag:String, ?container:Container):T {
    if (container == null) container = this;
    var name = getMappingKey(key, tag);
    var mapping:Mapping<T> = cast mappings.get(name);
    if (mapping == null) {
      if (parent != null) return parent.__get(key, tag, container);
      throw 'No mapping was found for ${name}';
    }
    return mapping.getValue(container);
  }

  public macro function has(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var key = capsule.macro.MappingBuilder.getMappingKey(def);
    var possibleTag = capsule.macro.MappingBuilder.extractMappingTag(def);
    if (possibleTag != null) tag = possibleTag;
    return macro @:pos(ethis.pos) $ethis.__has($key, $tag);
  }

  public function __has(key:String, ?tag:String):Bool {
    var name = getMappingKey(key, tag);
    if (mappings.exists(name)) return true;
    if (parent != null) return parent.__has(key, tag);
    return false;
  }

  function getMappingKey(type:String, name:String):String {
    if (name == null) name = '';
    return '$type#$name';
  }

}
