package capsule2.internal;

import haxe.macro.Expr;

using haxe.macro.Tools;
using capsule2.internal.Tools;

class MappingBuilder {
  public static function createIdentifier(expr:Expr) {
    return expr.resolveComplexType().toType().toString();
  }

  public static function getComplexType(target:Expr) {
    return target.resolveComplexType();
  }
}
