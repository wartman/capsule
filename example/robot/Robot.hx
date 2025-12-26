package robot;

class Robot {
	public final head:Head;
	public final body:Body;
	public final legs:Legs;
	public final arms:Arms;

	public function new(head, body, legs, arms) {
		this.head = head;
		this.body = body;
		this.legs = legs;
		this.arms = arms;
	}
}
