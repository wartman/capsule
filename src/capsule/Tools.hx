package capsule;

class Tools {
  @:noUsing
  public static macro function getIdentifier(e) {
    var id = capsule.internal.Builder.createIdentifier(e);
    return macro $v{id};
  }

  @:noUsing
  public static macro function getDependencies(expr) {
    var deps = capsule.internal.Builder.getDependencies(expr, expr.pos).map(id -> macro $v{id});
    return macro [ $a{deps} ];
  }

  public static macro function withSingleton(
    container:haxe.macro.Expr.ExprOf<Container>,
    target:haxe.macro.Expr,
    factory:haxe.macro.Expr
  ):haxe.macro.Expr.ExprOf<Container> {
    return macro {
      var container = $container;
      container.bind($target).toShared($factory);
      container;
    }
  }

  public static macro function withTransient(
    container:haxe.macro.Expr.ExprOf<Container>,
    target:haxe.macro.Expr,
    factory:haxe.macro.Expr
  ):haxe.macro.Expr.ExprOf<Container> {
    return macro {
      var container = $container;
      container.bind($target).to($factory);
      container;
    }
  }
}
