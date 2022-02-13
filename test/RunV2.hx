import medic.Runner;

function main() {
  var runner = new Runner();
  runner.add(new capsule2.ContainerTest());
  runner.add(new capsule2.ModuleTest());
  runner.run();
}
