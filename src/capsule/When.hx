package capsule;

class When<T> {
	final mapping:Mapping<T>;

	public function new(mapping) {
		this.mapping = mapping;
	}

	public macro function resolved(expr);
}
