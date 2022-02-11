package capsule2.internal;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.Tools;
using capsule2.internal.Tools;

class FactoryBuilder {
  public static function createFactory(expr:Expr, ret:ComplexType, pos:Position) {
    var body:Array<Expr> = [];

    switch expr.expr {
      case EFunction(_, f):
        var deps = compileArgs(f.args.map(a -> a.type.toType()));
        body.push(macro ${expr}($a{deps}));
      default: 
        var type = Context.typeof(expr);
        switch type {
          case TType(_, _):
            var path = expr.toString().split('.').concat([ 'new' ]);
            return createFactory(macro @:pos(pos) $p{path}, ret, pos);
          case TFun(args, _):
            var deps = compileArgs(args.map(a -> a.t));
            body.push(macro var factory = ${expr});
            body.push(macro factory($a{deps}));
          default:
            return macro new capsule2.provider.ValueProvider<$ret>(${expr});
        }
    }

    return macro new capsule2.provider.FactoryProvider(@:pos(pos) function (container:capsule2.Container):$ret {
      return $b{body};
    });
  }

  static function compileArgs(args:Array<Type>):Array<Expr> {
    var exprs:Array<Expr> = [];
    for (arg in args) {
      var id = arg.toString();
      exprs.push(macro container.getMappingById($v{id}).resolve());
    }
    return exprs;
  }
}