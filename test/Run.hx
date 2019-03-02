import medic.Runner;
import capsule.ContainerTest;
import capsule.ModuleTest;

class Run {

  public static function main() {
    var runner = new Runner();
    runner.add(new ContainerTest());
    runner.add(new ModuleTest());
    runner.run();
  }

}
