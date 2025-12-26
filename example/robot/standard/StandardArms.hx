package robot.standard;

class StandardArms implements Arms {
	public function new() {}

	public function pickUp(target:String):String {
		return 'Picks up $target';
	}
}
