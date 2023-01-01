package capsule;

using Lambda;

class Container {
  public static macro function build(...modules);

  final parent:Null<Container>;
  final mappings:Array<Mapping<Dynamic>> = [];

  public function new(?parent) {
    this.parent = parent;
  }

  public macro function map(target);

  public macro function get(target);
  
  public macro function getMapping(target);

  public macro function instantiate(target);

  public macro function use(...modules);

  public function getChild() {
    return new Container(this);
  }

  public function getMappingById<T>(id:Identifier #if debug , ?pos:haxe.PosInfos #end):Mapping<T> {
    var mapping:Null<Mapping<T>> = recursiveGetMappingById(id #if debug , pos #end);
    if (mapping == null) return addMapping(new Mapping(id, this));
    return mapping;
  }

  function recursiveGetMappingById<T>(id:Identifier #if debug , ?pos:haxe.PosInfos #end):Mapping<T> {
    var mapping:Null<Mapping<T>> = cast mappings.find(mapping -> mapping.id == id);
    if (mapping == null && parent != null) {
      var mapping = parent.recursiveGetMappingById(id #if debug , pos #end);  
      if (mapping != null) return addMapping(mapping.clone(this));
    }
    return mapping;
  }

  function addOrGetMappingForId<T>(id:String):Mapping<T> {
    if (mappings.exists(m -> m.id == id)) {
      return getMappingById(id);
    }
    return addMapping(new Mapping(id, this));
  }

  function addMapping<T>(mapping:Mapping<T>):Mapping<T> {
    mappings.push(mapping);
    return mapping;
  }

  function useModule(module:Module) {
    module.provide(this);
    return this;
  }
}
