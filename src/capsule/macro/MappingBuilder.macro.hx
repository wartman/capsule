package capsule.macro;

import haxe.macro.Expr;

using haxe.macro.Tools;
using capsule.macro.BuilderTools;

class MappingBuilder {
  public static function create(expr:Expr, ?tag:ExprOf<String>) {
    var type = expr.resolveComplexType();
    var identifier = IdentifierBuilder.create(type.toType(), expr.pos, tag);
    return macro @:pos(expr.pos) (new capsule.Mapping(${identifier}):capsule.Mapping<$type>);
  }
}
