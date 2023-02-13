package coffeemaker;

interface Heater {
	public function on():Void;
	public function off():Void;
	public function isHot():Bool;
}
