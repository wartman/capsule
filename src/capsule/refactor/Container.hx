package capsule.refactor;

import haxe.ds.Map;

using Type;

typedef ContainerGetOptions<T> = {
  ?fallbackToUntaggedType:Bool
};

class Container {
  
  final parent:Container;
  final mappings:Map<Identifier, Mapping<Dynamic>> = [];

  public function new(?parent:Container) {
    this.parent = parent;
    addMapping(new Mapping(
      new Identifier(this.getClass().getClassName()),
      ProvideValue(this)
    ));
  }

  public function getChild() {
    return new Container(this);
  }

  public function use(service:Service):Void {
    service.register(this);
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

  public inline function getMappingByDependency<T>(
    dep:Dependency<T>,
    ?options:ContainerGetOptions<T>
  ):Mapping<T> {
    return getMappingByIdentifier(dep, options);
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
