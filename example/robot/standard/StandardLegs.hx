package robot.standard;

class StandardLegs implements Legs {
	public function new() {}

	public function moveTo(target:String):String {
		return 'Moves to $target';
	}
}
