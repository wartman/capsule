package robot.standard;

class StandardBrain implements Brain {
	public function new() {}

	public function consider(target:String):String {
		return 'Is neutral about $target.';
	}
}
