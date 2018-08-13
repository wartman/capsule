package capsule.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
using Lambda;

// Stolen more or less completely from minject for now
// see this, just to be safe: https://github.com/massiveinteractive/minject/blob/master/LICENSE
class TypeHelpers {

  /**
    Returns a string representing the type for the supplied value

    - if expr is a type (String, foo.Bar) result is full type path
    - anything else is passed to `Injector.getValueType` which will attempt to determine a
      runtime type name.
  **/
  public static function getExprType(expr:Expr):Expr
  {
    switch (expr.expr)
    {
      case EConst(CString(_)): return expr;
      default:
    }
    var name = getExprTypeName(expr);
    return macro $v{name};
    // switch (Context.typeof(expr))
    // {
    //   case TType(_, _):
    //     var expr = expr.toString();
    //     try
    //     {
    //       var type = getType(Context.getType(expr));
    //       var index = type.indexOf("<");
    //       var typeWithoutParams = (index>-1) ? type.substr(0, index) : type;
    //       return macro $v{typeWithoutParams};
    //     }
    //     catch (e:Dynamic) {}
    //   default:
    // }
    return expr;
  }

  public static function getExprTypeName(expr:Expr):String {
    return switch (Context.typeof(expr)) {
      case TType(_, _):
        var expr = expr.toString();
        try {
          var type = getType(Context.getType(expr));
          var index = type.indexOf("<");
          var typeWithoutParams = (index>-1) ? type.substr(0, index) : type;
          typeWithoutParams;
        }
        catch (e:Dynamic) {
          '';
        }
      default: '';
    }
  }

  public static function getValueId(expr:Expr):Expr
  {
    var type = Context.typeof(expr).toString();
    return macro $v{type};
  }

  public static function getValueType(expr:Expr):ComplexType
  {
    switch (expr.expr)
    {
      case EConst(CString(type)):
        return getComplexType(type);
      default:
    }
    switch (Context.typeof(expr))
    {
      case TType(_, _):
        return getComplexType(expr.toString());
      default:
    }
    return null;
  }

  static function getComplexType(type:String):ComplexType
  {
    return switch (Context.parse('(null:Null<$type>)', Context.currentPos()))
    {
      case macro (null:$type): type;
      default: null;
    }
  }

  public static function getType(type:Type):String
  {
    return followType(type).toString();
  }

  public static function isNullable(type:Type):Bool {
    switch (type) {
      // hmm.
      case TAbstract(t, inst):
        if (Std.string(t) == 'Null')
          return true;
        return false;
      case TType(t, params):
        if (Std.string(t) == 'Null')
          return true;
        return switch (t.get().type)
        {
          case TAnonymous(_): false;
          case ref: isNullable(ref);
        }
      default:
        return false;
    }
  }

  /**
    Follow TType references, but not if they point to TAnonymous
  **/
  static function followType(type:Type):Type
  {
    switch (type)
    {
      case TType(t, params):
        if (Std.string(t) == 'Null')
          return followType(params[0]);
        return switch (t.get().type)
        {
          case TAnonymous(_): type;
          case ref: followType(ref);
        }
      default:
        return type;
    }
  }

}
