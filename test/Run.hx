import nuke.HashTest;

using Medic;

function main() {
  var runner = new Runner();
  runner.add(new HashTest());
  runner.run();
}