package robot.generic;

import robot.standard.StandardHead;

class GenericRobot<T:Brain> extends Robot {
	public function new(brain:T, body, legs, arms) {
		super(new StandardHead(brain), body, legs, arms);
	}
}
