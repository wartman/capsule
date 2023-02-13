package fixture;

class SimpleWithDep implements SimpleService {
	final value:ValueService;

	public function new(value) {
		this.value = value;
	}

	public function getValue():String {
		return value.get();
	}
}
