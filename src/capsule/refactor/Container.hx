package capsule.refactor;

import haxe.ds.Map;

using Type;

class Container {
  
  final mappings:Map<Identifier, Mapping<Dynamic>> = [];

  public function new() {
    addMapping(new Mapping(
      new Identifier(this.getClass().getClassName()),
      ProvideValue(this)
    ));
  }

  public macro function map(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var mapping = capsule.refactor.macro.MappingBuilder.create(def, tag);
    return macro @:pos(ethis.pos) $ethis.addMapping(${mapping});
  }

  public macro function get(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var dep = capsule.refactor.macro.IdentifierBuilder.createDependency(def, tag);
    return macro @:pos(ethis.pos) $ethis.getMappingByDependency(${dep}).getValue(${ethis});
  }

  public function addMapping<T>(mapping:Mapping<T>):Mapping<T> {
    if (mappings.exists(mapping.identifier)) {
      return getMappingByIdentifier(mapping.identifier);
    }
    mappings.set(mapping.identifier, mapping);
    return mapping;
  }

  public inline function getMappingByDependency<T>(dep:Dependency<T>):Mapping<T> {
    return getMappingByIdentifier(dep);
  }

  public function getMappingByIdentifier<T>(id:Identifier):Mapping<T> {
    var m = mappings.get(id);
    if (m == null) {
      throw 'Mapping not found: ${id.toString()}';
    }
    return cast m;
  }

  public function getValueByIdentifier<T>(id:Identifier):T {
    return getMappingByIdentifier(id).getValue(this);
  }

}
