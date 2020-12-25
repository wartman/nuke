package atom.injector;

class StaticInjector implements Injector {
  final rules:Array<String> = [];

  public function new() {}
  
  public function insert(rule:CssRule, index:Int) {
    rules.push(rule);
    // more?
  }

  public function toString() {
    return rules.join('\n');
  }
}
