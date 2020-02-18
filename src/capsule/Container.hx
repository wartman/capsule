package capsule;

import haxe.PosInfos;
import haxe.ds.Map;

using Type;

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

  public macro function use(ethis:haxe.macro.Expr, service:haxe.macro.Expr) {
    var e:haxe.macro.Expr = if (haxe.macro.Context.unify(haxe.macro.Context.typeof(service), haxe.macro.Context.getType('capsule.ServiceProvider'))) {
      service;
    } else {
      macro @:pos(service.pos) $ethis.build(${service});
    }
    return macro @:pos(ethis.pos) $ethis.useServiceProvider(${e});
  }

  public macro function map(
    ethis:haxe.macro.Expr,
    def:haxe.macro.Expr,
    ?tag:haxe.macro.Expr.ExprOf<String>
  ) {
    var mapping = capsule.macro.MappingBuilder.create(def, tag);
    return macro @:pos(ethis.pos) $ethis.addMapping(${mapping});
  }

  public macro function get(
    ethis:haxe.macro.Expr,
    def:haxe.macro.Expr,
    ?tag:haxe.macro.Expr.ExprOf<String>
  ):haxe.macro.Expr {
    var dep = capsule.macro.IdentifierBuilder.createDependency(def, tag);
    return macro @:pos(ethis.pos) $ethis.getMappingByDependency(${dep}).getValue(${ethis});
  }

  public macro function getMapping(
    ethis:haxe.macro.Expr,
    def:haxe.macro.Expr,
    ?tag:haxe.macro.Expr.ExprOf<String>
  ):haxe.macro.Expr {
    var dep = capsule.macro.IdentifierBuilder.createDependency(def, tag);
    return macro @:pos(ethis.pos) $ethis.getMappingByDependency(${dep});
  }

  public macro function has(
    ethis:haxe.macro.Expr,
    def:haxe.macro.Expr,
    ?tag:haxe.macro.Expr.ExprOf<String>
  ) {
    var id = capsule.macro.IdentifierBuilder.createDependency(def, tag);
    return macro @:pos(ethis.pos) $ethis.hasMappingByIdentifier(${id});
  }

  public macro function build(
    ethis:haxe.macro.Expr.ExprOf<Class<Dynamic>>,
    def:haxe.macro.Expr
  ) {
    var mapping = capsule.macro.MappingBuilder.create(def, macro null);
    return macro @:pos(ethis.pos) ${mapping}.toClass(${def}).getValue(${ethis});
  }

  public function useServiceProvider(service:ServiceProvider):Void {
    service.register(this);
  }

  public function addMapping<T>(mapping:Mapping<T>):Mapping<T> {
    if (mappings.exists(mapping.identifier)) {
      return getMappingByIdentifier(mapping.identifier);
    }
    mappings.set(mapping.identifier, mapping);
    return mapping;
  }

  public inline function getMappingByDependency<T>(dep:Dependency<T> #if debug , ?pos:PosInfos #end):Mapping<T> {
    return getMappingByIdentifier(dep #if debug , pos #end);
  }

  public function hasMappingByIdentifier(id:Identifier) {
    return mappings.exists(id);
  }

  public function getMappingByIdentifier<T>(id:Identifier #if debug , ?pos:PosInfos #end):Mapping<T> {
    var m = mappings.get(id);
    if (m == null) {
      if (parent != null) return parent.getMappingByIdentifier(id);
      throw new MappingNotFoundError(id #if debug , pos #end);
    }
    return cast m;
  }

  public function getValueByIdentifier<T>(id:Identifier):T {
    return getMappingByIdentifier(id).getValue(this);
  }

}
