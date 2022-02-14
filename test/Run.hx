import medic.Runner;

function main() {
  var runner = new Runner();
  runner.add(new capsule.ContainerTest());
  runner.add(new capsule.ModuleTest());
  runner.run();
}
