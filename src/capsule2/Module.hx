package capsule2;

@:autoBuild(capsule2.ModuleBuilder.build())
interface Module {
  public function provide(container:Container):Void;  
}
