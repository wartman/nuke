package atom;

interface Injector {
  public function insert(rule:CssRule, index:Int):Void;
  public function toString():String;
}
