#if macro
package capsule.refactor.macro;

import haxe.macro.Expr;

using haxe.macro.Tools;

class MappingBuilder {
  
  public static function create(expr:Expr, ?tag:ExprOf<String>) {
    if (tag == null) tag = IdentifierBuilder.exprToTag(expr);
    var type = IdentifierBuilder.exprToType(expr);
    var identifier = IdentifierBuilder.create(type.toType(), tag);
    return macro @:pos(expr.pos) (new capsule.refactor.Mapping(${identifier}):capsule.refactor.Mapping<$type>);
  }

}
#end
