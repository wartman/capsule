package robot.logger;

class DefaultLogger implements Logger {
	public function new() {}

	public function log(message:String):Void {
		trace(message);
	}
}
