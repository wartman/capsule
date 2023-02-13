package generics;

class GenericValue<T> implements Value<T> {
	final value:T;

	public function new(value) {
		this.value = value;
	}

	public function getValue() {
		return value;
	}
}
