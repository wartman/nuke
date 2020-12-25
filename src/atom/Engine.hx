package atom;

import atom.injector.*;

class Engine {
  static var instance:Engine = null;

  public static function getInstance() {
    if (instance == null) { 
      instance = new Engine(
        #if (js && !nodejs)
          #if debug new DomInjector() #else new CssOmInjector() #end
        #else
          new StaticInjector()
        #end
      );
    }
    return instance;
  }

  final injector:Injector;
  final ruleIndexes:Array<String> = [];

  public function new(injector) {
    this.injector = injector;
  }

  public function add(key:String, rule:String) {
    if (!ruleIndexes.contains(key)) {
      injector.insert(rule, ruleIndexes.length);
      ruleIndexes.push(key);
    }
  }

  public function stylesToString() {
    return injector.toString();
  }
}
