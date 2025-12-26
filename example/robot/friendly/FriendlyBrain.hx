package robot.friendly;

class FriendlyBrain implements Brain {
	public function new() {}

	public function consider(target:String):String {
		return 'Would like $target to be its friend.';
	}
}
