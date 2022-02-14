package capsule;

@:autoBuild(capsule.ModuleBuilder.build())
interface Module {
  public function provide(container:Container):Void;  
}
