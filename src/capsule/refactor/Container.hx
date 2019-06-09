package capsule.refactor;

using Type;
using Lambda;

class Container {
  
  final mappings:Array<Mapping<Dynamic>> = [];

  public function new() {
    addMapping(new Mapping(
      new Identifier(this.getClass().getClassName()),
      Provider.value(this)
    ));
  }

  public macro function map(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var key = capsule.refactor.macro.MappingBuilder.getMappingKey(def);
    var type = capsule.refactor.macro.MappingBuilder.getMappingType(def);
    var possibleTag = capsule.refactor.macro.MappingBuilder.extractMappingTag(def);
    if (possibleTag != null) tag = possibleTag;
    return macro @:pos(ethis.pos) $ethis.mapIdentifier(
      new Identifier($key, $tag),
      (null:$type)
    );
  }

  public macro function get(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var key = capsule.refactor.macro.MappingBuilder.getMappingKey(def);
    var type = capsule.refactor.macro.MappingBuilder.getMappingType(def);
    var possibleTag = capsule.refactor.macro.MappingBuilder.extractMappingTag(def);
    if (possibleTag != null) tag = possibleTag;
    return macro @:pos(ethis.pos) ($ethis.getValueByIdentifier(
      new Identifier($key, $tag)
    ):$type);
  }

  public function addMapping<T>(mapping:Mapping<T>):Mapping<T> {
    // todo: check if mapping exists first
    mappings.push(mapping);
    return mapping;
  }

  public function mapIdentifier<T>(identifier:Identifier, ?value:T):Mapping<T> {
    return addMapping(new Mapping(identifier));
  }

  public function getMappingByIdentifier<T>(id:Identifier):Mapping<T> {
    var m = mappings.find(m -> m.identifier == id);
    if (m == null) {
      throw 'Mapping not found: ${id.toString()}';
    }
    return cast m;
  }

  public function getValueByIdentifier<T>(id:Identifier):T {
    return getMappingByIdentifier(id).getValue(this);
  }

}
