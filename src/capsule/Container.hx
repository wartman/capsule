package capsule;

class Container {

  private var parent:Container;
  private var mappings:Map<String, Mapping<Dynamic>> = new Map();

  public function new(?parent:Container) {
    this.parent = parent;
  }

  public function getChildContainer():Container {
    return new Container(this);
  }

  public function provide(serviceProvider:ServiceProvider) {
    serviceProvider.register(this);
    return this;
  }

  public macro function map(ethis:haxe.macro.Expr, type:haxe.macro.Expr, ?id:haxe.macro.Expr.ExprOf<String>) {
    var typeId = capsule.macro.TypeHelpers.getExprType(type);
    var type = capsule.macro.TypeHelpers.getValueType(type);
    return macro @:pos(ethis.pos) $ethis.mapType($typeId, $id, (null:$type));
  }

  public function mapType<T>(type:String, ?id:String, ?value:T):Mapping<T> {
    var name = getMappingKey(type, id);
    if (mappings.exists(name)) return cast mappings.get(name);
    var mapping = new Mapping(type, id);
    mappings.set(name, mapping);
    return mapping;
  }

  public macro function get<T>(ethis:haxe.macro.Expr, type:haxe.macro.Expr, ?id:haxe.macro.Expr.ExprOf<String>) {
    return switch (type.expr) {
      case haxe.macro.Expr.ExprDef.EConst(haxe.macro.Expr.Constant.CString(_)): macro @:pos(ethis.pos) ${ethis}.getValue($type, $id);
      default:
        var typeId = capsule.macro.TypeHelpers.getExprType(type);
        macro @:pos(ethis.pos) ${ethis}.getValue($typeId, $id);
    }
  }

  public function getValue<T>(type:String, ?id:String, ?container:Container):T {
    if (container == null) container = this;
    var name = getMappingKey(type, id);
    var mapping:Mapping<T> = cast mappings.get(name);
    if (mapping == null) {
      if (parent != null) return parent.getValue(type, id, container);
      throw 'No mapping was found for ${mapping}';
    }
    return mapping.getValue(container);
  }

  private function getMappingKey(type:String, name:String):String {
    if (name == null) name = '';
    return '$type#$name';
  }

}
