package capsule;

class Container {

  private var parent:Container;
  private var mappings:Map<String, Mapping<Dynamic>> = new Map();

  public function new(?parent:Container, ?mappings:Map<String, Mapping<Dynamic>>) {
    this.parent = parent;
    if (mappings != null) this.mappings = mappings;
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

  public macro function map(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var key = capsule.macro.MappingBuilder.getMappingKey(def);
    var type = capsule.macro.MappingBuilder.getMappingType(def);
    var possibleTag = capsule.macro.MappingBuilder.extractMappingTag(def);
    if (possibleTag != null) tag = possibleTag;
    return macro @:pos(ethis.pos) $ethis.mapType($key, $tag, (null:$type));
  }

  public function mapType<T>(key:String, ?tag:String, ?value:T):Mapping<T> {
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
    return macro @:pos(ethis.pos) ($ethis.getValue($key, $tag):$type);
  }

  public function getValue<T>(key:String, ?tag:String, ?container:Container):T {
    if (container == null) container = this;
    var name = getMappingKey(key, tag);
    var mapping:Mapping<T> = cast mappings.get(name);
    if (mapping == null) {
      if (parent != null) return parent.getValue(key, tag, container);
      throw 'No mapping was found for ${name}';
    }
    return mapping.getValue(container);
  }

  private function getMappingKey(type:String, name:String):String {
    if (name == null) name = '';
    return '$type#$name';
  }

}
