package capsule2;

import capsule2.exception.MappingNotFoundException;

#if macro
  import haxe.macro.Expr;
  import capsule2.internal.MappingBuilder;
#end

using Lambda;

class Container {
  final parent:Null<Container>;
  final mappings:Array<Mapping<Dynamic>> = [];

  public function new(?parent) {
    this.parent = parent;
  }

  public function getChild() {
    return new Container(this);
  }

  public macro function map(self:Expr, target:Expr) {
    var identifier = MappingBuilder.createIdentifier(target);
    var type = MappingBuilder.getComplexType(target);
    return macro @:pos(self.pos) @:privateAccess $self.addMapping(
      (new capsule2.Mapping($v{identifier}, ${self}):capsule2.Mapping<$type>)
    );
  }

  function addMapping<T>(mapping:Mapping<T>):Mapping<T> {
    mappings.push(mapping);
    return mapping;
  }

  public function getMappingById<T>(id:Identifier #if debug , ?pos:haxe.PosInfos #end):Mapping<T> {
    var mapping:Null<Mapping<T>> = cast mappings.find(mapping -> mapping.id == id);
    if (mapping == null) throw new MappingNotFoundException(id #if debug , pos #end);
    return mapping;
  }
}
