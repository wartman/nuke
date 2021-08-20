package nuke.injector;

class StaticInjector implements Injector {
  #if (js && !nodejs)
    public final sheet:js.html.CSSStyleSheet = null;
  #end

  final rules:Array<String> = [];

  public function new() {}
  
  public function insert(rule:String, index:Int) {
    rules.push(rule);
    return 1;
    // more?
  }

  public function toString() {
    return rules.join('\n');
  }
}
