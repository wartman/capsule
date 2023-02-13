package coffeemaker;

class DefaultCoffeeLogger implements CoffeeLogger {
	public function new() {}

	public function log(message:String) {
		#if sys
		Sys.print(message);
		#else
		trace(message);
		#end
	}
}
