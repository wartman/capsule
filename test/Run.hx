import medic.Runner;
import capsule.ContainerTest;
import capsule.MappingTest;

class Run {

  public static function main() {
    var runner = new Runner();
    runner.add(new ContainerTest());
    runner.add(new MappingTest());
    runner.run();
  }

}
