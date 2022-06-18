package capsule;

#if macro
  import haxe.macro.Expr;
  import capsule.internal.Builder;
#end

using Lambda;

class Container {
  public static macro function build(...modules:ExprOf<Module>) {
    return ContainerBuilder.buildFromModules(modules.toArray());
  }

  final parent:Null<Container>;
  final bindings:Array<Binding<Dynamic>> = [];

  public function new(?parent) {
    this.parent = parent;
  }

  public function getChild() {
    return new Container(this);
  }

  public macro function map(self:Expr, target:Expr) {
    haxe.macro.Context.warning('Use `container.bind` instead. This warning will be removed in version 0.4.1.', self.pos);

    var identifier = Builder.createIdentifier(target);
    var type = Builder.getComplexType(target);
    return macro @:pos(self.pos) @:privateAccess ($self.addOrGetBindingForId($v{identifier}):capsule.Binding<$type>);
  }

  public macro function bind(self:Expr, target:Expr) {
    var identifier = Builder.createIdentifier(target);
    var type = Builder.getComplexType(target);
    return macro @:pos(self.pos) @:privateAccess ($self.addOrGetBindingForId($v{identifier}):capsule.Binding<$type>);
  }

  public macro function get(self:Expr, target:Expr) {
    var identifier = Builder.createIdentifier(target);
    var type = Builder.getComplexType(target);
    return macro @:pos(target.pos) ($self.getBindingById($v{identifier}):capsule.Binding<$type>).resolve();
  }

  public macro function getMapping(self:Expr, target:Expr) {
    haxe.macro.Context.warning('Use `container.getBinding` instead. This warning will be removed in version 0.4.1.', self.pos);
    
    var identifier = Builder.createIdentifier(target);
    var type = Builder.getComplexType(target);
    return macro @:pos(target.pos) ($self.getBindingById($v{identifier}):capsule.Binding<$type>);
  }
  
  public macro function getBinding(self:Expr, target:Expr) {
    var identifier = Builder.createIdentifier(target);
    var type = Builder.getComplexType(target);
    return macro @:pos(target.pos) ($self.getBindingById($v{identifier}):capsule.Binding<$type>);
  }

  public macro function instantiate(self:Expr, target:Expr) {
    var factory = Builder.createFactory(target, target.pos);
    return macro @:pos(target.pos) ${factory}($self);
  }

  public macro function use(self:Expr, ...modules:ExprOf<Module>) {
    var body = [ for (m in modules) macro @:privateAccess $self.useModule($self.instantiate(${m})) ];
    return macro @:pos(self.pos) {
      $b{body};
    }
  }

  public function getBindingById<T>(id:Identifier #if debug , ?pos:haxe.PosInfos #end):Binding<T> {
    var binding:Null<Binding<T>> = recursiveGetBindingById(id #if debug , pos #end);
    if (binding == null) return addBinding(new Binding(id, this));
    return binding;
  }

  function recursiveGetBindingById<T>(id:Identifier #if debug , ?pos:haxe.PosInfos #end):Binding<T> {
    var binding:Null<Binding<T>> = cast bindings.find(binding -> binding.id == id);
    if (binding == null) {
      if (parent == null) return null;
      var binding = parent.recursiveGetBindingById(id #if debug , pos #end);  
      if (binding != null) return binding.withContainer(this);
    }
    return binding;
  }

  function addOrGetBindingForId<T>(id:String):Binding<T> {
    if (bindings.exists(m -> m.id == id)) {
      return getBindingById(id);
    }
    return addBinding(new Binding(id, this));
  }

  function addBinding<T>(binding:Binding<T>):Binding<T> {
    bindings.push(binding);
    return binding;
  }

  function useModule(module:Module) {
    module.provide(this);
    return this;
  }
}
