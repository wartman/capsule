#if macro
package capsule.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
using capsule.macro.Common;

class MappingBuilder {

  public static function extractMappingTag(expr:Expr):Null<ExprOf<String>> {
    return switch (expr.expr) {
      case EVars(vars):
        if (vars.length > 1)
          Context.error('Only one var should be used here', expr.pos);
        var name = vars[0].name;
        if (name != '_') {
          macro @:pos(expr.pos) $v{name};
        } else {
          null;
        }
      default: null;
    }
  }

  public static function getMappingKey(expr:Expr):ExprOf<String> {
    var id = getExprTypeName(expr);
    return macro $v{id};
  }

  public static function getMappingType(expr:Expr):ComplexType {
    switch (expr.expr) {
      case EConst(CString(name)):
        return parseType(name, expr.pos);
      case EVars(vars):
        if (vars.length > 1)
          Context.error('Only one var should be used here', expr.pos);
        return vars[0].type;
      default:
    }

    switch (Context.typeof(expr)) {
      case TType(_, _):
        return parseType(expr.toString(), expr.pos);
      default:
    }

    return null;
  }

  public static function getExprTypeName(expr:Expr):String {
    switch (expr.expr) {
      case EVars(vars):
        if (vars.length > 1)
          Context.error('Only one var should be used here', expr.pos);
        return vars[0].type.toType().toString();
      case EConst(CString(s)):
        return parseType(s, expr.pos).toType().toString();
      default:
    }

    return switch (Context.typeof(expr)) {
      case TType(_, _):
        try {
          var type = getTypeName(Context.getType(expr.toString()));
          type;
        } catch (e:Dynamic) {
          '';
        }
      default: '';
    }
  }

  public static function getTypeName(type:Type):String {
    return type.followType().toString();
  }

  public static function parseType(name:String, pos:Position):ComplexType {
    return switch(Context.parse('(null:${name})', pos)) {
      case macro (null:$type): type;
      default: null;
    }
  }

}
#end
