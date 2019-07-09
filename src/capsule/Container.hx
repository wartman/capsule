package capsule;

import haxe.ds.Map;

using Type;

typedef ContainerGetOptions<T> = {
  ?fallbackToUntaggedType:Bool
};

class Container {
  
  final parent:Container;
  final mappings:Map<Identifier, Mapping<Dynamic>>;

  public function new(?parent:Container, ?mappings:Map<Identifier, Mapping<Dynamic>>) {
    this.parent = parent;
    this.mappings = mappings != null ? mappings : [];
    addMapping(new Mapping(
      new Identifier(this.getClass().getClassName()),
      ProvideValue(this)
    ));
  }

  public function extend(container:Container) {
    return new Container(container, mappings);
  }

  public function getChild() {
    return new Container(this);
  }

  public function use(service:ServiceProvider):Void {
    service.register(this);
  }

  public macro function map(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var mapping = capsule.macro.MappingBuilder.create(def, tag);
    return macro @:pos(ethis.pos) $ethis.addMapping(${mapping});
  }

  public macro function get(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var dep = capsule.macro.IdentifierBuilder.createDependency(def, tag);
    return macro @:pos(ethis.pos) $ethis.getMappingByDependency(${dep}).getValue(${ethis});
  }

  public macro function has(ethis:haxe.macro.Expr, def:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var id = capsule.macro.IdentifierBuilder.createDependency(def, tag);
    return macro @:pos(ethis.pos) $ethis.hasMappingByIdentifier(${id});
  }

  public function addMapping<T>(mapping:Mapping<T>):Mapping<T> {
    if (mappings.exists(mapping.identifier)) {
      return getMappingByIdentifier(mapping.identifier);
    }
    mappings.set(mapping.identifier, mapping);
    return mapping;
  }

  public inline function getMappingByDependency<T>(
    dep:Dependency<T>,
    ?options:ContainerGetOptions<T>
  ):Mapping<T> {
    return getMappingByIdentifier(dep, options);
  }

  public function hasMappingByIdentifier(id:Identifier) {
    return mappings.exists(id);
  }

  public function getMappingByIdentifier<T>(
    id:Identifier,
    ?options:ContainerGetOptions<T>
  ):Mapping<T> {
    if (options == null) {
      options = { fallbackToUntaggedType: false };
    }
    var m = mappings.get(id);
    if (m == null) {
      function finish() {
        if (id.hasTag() && options.fallbackToUntaggedType) {
          return getMappingByIdentifier(id.withoutTag());
        }
        throw new MappingNotFoundError(id);
      }

      if (parent != null) try {
        return parent.getMappingByIdentifier(id, options);
      } catch (_:MappingNotFoundError) {
        return finish();
      }

      return finish();
    }
    return cast m;
  }

  public function getValueByIdentifier<T>(
    id:Identifier,
    ?options:ContainerGetOptions<T>
  ):T {
    return getMappingByIdentifier(id, options).getValue(this);
  }

}
