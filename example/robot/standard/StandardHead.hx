package robot.standard;

class StandardHead implements Head {
	final brain:Brain;

	public function new(brain) {
		this.brain = brain;
	}

	public function lookAt(target:String):String {
		return 'Looks at $target. ' + brain.consider(target);
	}
}
