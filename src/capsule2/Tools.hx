package capsule2;

class Tools {
  public static macro function getIdentifier(e) {
    var id = capsule2.internal.Builder.createIdentifier(e);
    return macro $v{id};
  }

  public static macro function getDependencies(expr) {
    var deps = capsule2.internal.Builder.getDependencies(expr, expr.pos).map(id -> macro $v{id});
    return macro [ $a{deps} ];
  }
}
