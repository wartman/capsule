package capsule.refactor;

import haxe.ds.Map;

using Type;

class Container {
  
  final mappings:Map<Identifier, Mapping<Dynamic>> = [];

  public function new() {
    addMapping(new Mapping(
      new Identifier(this.getClass().getClassName()),
      Provider.value(this)
    ));
  }

  public macro function map(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var identifier = capsule.refactor.macro.IdentifierTools.getIdentifier(def, tag);
    var type = capsule.refactor.macro.IdentifierTools.getExprType(def);
    return macro @:pos(ethis.pos) ($ethis.mapIdentifier(${identifier}):capsule.refactor.Mapping<$type>);
  }

  public macro function get(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var identifier = capsule.refactor.macro.IdentifierTools.getIdentifier(def, tag);
    var type = capsule.refactor.macro.IdentifierTools.getExprType(def);
    return macro @:pos(ethis.pos) ($ethis.getValueByIdentifier(${identifier}):$type);
  }

  public function addMapping<T>(mapping:Mapping<T>):Mapping<T> {
    if (mappings.exists(mapping.identifier)) {
      return getMappingByIdentifier(mapping.identifier);
    }
    mappings.set(mapping.identifier, mapping);
    return mapping;
  }

  public function mapIdentifier<T>(identifier:Identifier):Mapping<T> {
    return addMapping(new Mapping(identifier));
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
