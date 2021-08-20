package nuke;

import nuke.internal.Hash.hash;

using Medic;

class HashTest implements TestCase { 
  public function new() {}

  @:test('Hashes are consistant')
  public function testConsistant() {
    var a = hash('color:blue');
    var b = hash('color:blue');
    a.equals(b);
  }

  @:test('Hashes do not change')
  public function testStatic() {
    var a = hash('color:blue');
    a.equals('E2BE12FC');
  }

  @:test('Strings return unique hashes')
  public function testUnique() {
    var a = hash('color:red');
    var b = hash('color:blue');
    var c = hash('color: red'); // spaces matter

    a.notEquals(b);
    a.notEquals(c);
  }
}
