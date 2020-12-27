package atom;

interface Injector {
  public function insert(rule:CssRule, index:Int):Int;
  public function toString():String;
}
