package capsule2;

import capsule2.exception.MappingNotFoundException;

#if macro
  import haxe.macro.Expr;
  import capsule2.internal.Builder;
#end

using Lambda;

class Container {
  public static macro function create(...modules:ExprOf<Module>) {
    return ContainerBuilder.createContainer(modules.toArray());
  }

  final parent:Null<Container>;
  final mappings:Array<Mapping<Dynamic>> = [];

  public function new(?parent) {
    this.parent = parent;
  }

  public function getChild() {
    return new Container(this);
  }

  public macro function map(self:Expr, target:Expr) {
    var identifier = Builder.createIdentifier(target);
    var type = Builder.getComplexType(target);
    return macro @:pos(self.pos) @:privateAccess $self.addMapping(
      (new capsule2.Mapping($v{identifier}, ${self}):capsule2.Mapping<$type>)
    );
  }

  public macro function get(self:Expr, target:Expr) {
    var identifier = Builder.createIdentifier(target);
    var type = Builder.getComplexType(target);
    return macro @:pos(target.pos) ($self.getMappingById($v{identifier}):capsule2.Mapping<$type>).resolve();
  }
  
  public macro function getMapping(self:Expr, target:Expr) {
    var identifier = Builder.createIdentifier(target);
    var type = Builder.getComplexType(target);
    return macro @:pos(target.pos) ($self.getMappingById($v{identifier}):capsule2.Mapping<$type>);
  }

  public macro function build(self:Expr, target:Expr) {
    var factory = Builder.createFactory(target, target.pos);
    return macro @:pos(target.pos) ${factory}($self);
  }

  public function getMappingById<T>(id:Identifier #if debug , ?pos:haxe.PosInfos #end):Mapping<T> {
    var mapping:Null<Mapping<T>> = cast mappings.find(mapping -> mapping.id == id);
    if (mapping == null) {
      if (parent == null) throw new MappingNotFoundException(id #if debug , pos #end);
      return parent
        .getMappingById(id #if debug , pos #end)
        .withContainer(this);
    }
    return mapping;
  }

  function addMapping<T>(mapping:Mapping<T>):Mapping<T> {
    mappings.push(mapping);
    return mapping;
  }
}
