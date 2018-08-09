package test;

import haxe.unit.TestRunner;
import test.capsule.ContainerTest;

class Run {

  public static function main() {
    // Using haxe.unit for the moment.
    var runner = new TestRunner();
    runner.add(new ContainerTest());
    runner.run();
  }

}