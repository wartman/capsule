package capsule.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
using capsule.macro.Common;

class MappingBuilder {

  public static function extractMappingTag(expr:Expr):Null<ExprOf<String>> {
    return switch (expr.expr) {
      case EConst(CString(s)):
        var t = parseType(s, expr.pos).toType();
        if (!t.isTag()) return null;
        var name = t.extractTagName();
        macro $v{name};
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
    var t = doGetMappingType(expr);
    if (t.toType().isTag()) {
      return t.toType().extractTagType().toComplexType();
    }
    return t;
  }

  static function doGetMappingType(expr:Expr):ComplexType {
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
        var t = vars[0].type.toType();
        if (t.isTag()) return t.extractTagType().toString();
        return t.toString();
      case EConst(CString(s)):
        var t = parseType(s, expr.pos).toType();
        if (t.isTag()) return t.extractTagType().toString();
        return t.toString();
      default:
    }

    return switch (Context.typeof(expr)) {
      case TType(_, _):
        try {
          var type = Context.getType(expr.toString()).followType();
          if (type.isTag()) return type.extractTagType().toString();
          type.toString();
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