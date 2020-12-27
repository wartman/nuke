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

  public function add(key:String, rule:String):Int {
    if (!ruleIndexes.contains(key)) {
      var ret = injector.insert(rule, ruleIndexes.length);
      ruleIndexes.push(key);
      return ret;
    }
    return 0;
  }

  public function stylesToString() {
    return injector.toString();
  }
}
