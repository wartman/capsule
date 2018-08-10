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

  public macro function map(ethis:haxe.macro.Expr, type:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    var typeId = capsule.macro.TypeHelpers.getExprType(type);
    var type = capsule.macro.TypeHelpers.getValueType(type);
    return macro @:pos(ethis.pos) $ethis.mapType($typeId, $tag, (null:$type));
  }

  public function mapType<T>(type:String, ?tag:String, ?value:T):Mapping<T> {
    var name = getMappingKey(type, tag);
    if (mappings.exists(name)) return cast mappings.get(name);
    var mapping = new Mapping(type, tag);
    mappings.set(name, mapping);
    return mapping;
  }

  public macro function get(ethis:haxe.macro.Expr, type:haxe.macro.Expr, ?tag:haxe.macro.Expr.ExprOf<String>) {
    return switch (type.expr) {
      case haxe.macro.Expr.ExprDef.EConst(haxe.macro.Expr.Constant.CString(_)): macro @:pos(ethis.pos) ${ethis}.getValue($type, $tag);
      default:
        var typeId = capsule.macro.TypeHelpers.getExprType(type);
        var complex = capsule.macro.TypeHelpers.getValueType(type);
        macro @:pos(ethis.pos) (${ethis}.getValue($typeId, $tag):$complex);
    }
  }

  public function getValue<T>(type:String, ?tag:String, ?container:Container):T {
    if (container == null) container = this;
    var name = getMappingKey(type, tag);
    var mapping:Mapping<T> = cast mappings.get(name);
    if (mapping == null) {
      if (parent != null) return parent.getValue(type, tag, container);
      throw 'No mapping was found for ${mapping}';
    }
    return mapping.getValue(container);
  }

  private function getMappingKey(type:String, name:String):String {
    if (name == null) name = '';
    return '$type#$name';
  }

}
