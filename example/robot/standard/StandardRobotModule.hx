package robot.standard;

import capsule.*;

class StandardRobotModule implements Module {
	public function new() {}

	public function provide(container:Container) {
		container.bind(Robot).to(Robot);
		container.bind(Brain).to(StandardBrain);
		container.bind(Head).to(StandardHead);
		container.bind(Body).to(StandardBody);
		container.bind(Arms).to(StandardArms);
		container.bind(Legs).to(StandardLegs);
		container.when(Array(Robot)).resolved((robots, standard:Robot) -> {
			robots.concat([standard]);
		});
	}
}
