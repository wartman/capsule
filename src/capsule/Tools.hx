package capsule;

class Tools {
  public static macro function getIdentifier(e) {
    var id = capsule.internal.Builder.createIdentifier(e);
    return macro $v{id};
  }

  public static macro function getDependencies(expr) {
    var deps = capsule.internal.Builder.getDependencies(expr, expr.pos).map(id -> macro $v{id});
    return macro [ $a{deps} ];
  }
}