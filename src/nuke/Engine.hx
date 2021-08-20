package nuke;

import nuke.injector.*;

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
  
  /**
    Set the Engine instance Atom will use. The previous instance,
    if any, will be returned.
  **/
  public static function setInstance(engine:Engine) {
    var previousInstance = instance;
    instance = engine;
    return previousInstance;
  }
  
  final injector:Injector;
  final ruleIndexes:Array<String> = [];

  public function new(injector) {
    this.injector = injector;
  }

  public function add(atom:Atom):Int {
    var key = atom.getHash();
    if (!ruleIndexes.contains(key)) {
      var ret = injector.insert(atom.render(), ruleIndexes.length);
      ruleIndexes.push(key);
      return ret;
    }
    return 0;
  }

  public function stylesToString() {
    return injector.toString();
  }
}
