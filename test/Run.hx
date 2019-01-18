import hex.unittest.notifier.*;
import hex.unittest.runner.*;
import capsule.ContainerTest;
import capsule.ModuleTest;

class Run {

  public static function main() {
    var emu = new ExMachinaUnitCore();
    emu.addListener(new ConsoleNotifier(false));
    emu.addListener(new ExitingNotifier());
    emu.addTest(ContainerTest);
    emu.addTest(ModuleTest);
    emu.run();
  }

}