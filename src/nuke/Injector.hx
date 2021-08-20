package nuke;

interface Injector {
  #if (js && !nodejs)
    public final sheet:js.html.CSSStyleSheet;
  #end
  public function insert(rule:String, index:Int):Int;
  public function toString():String;
}
