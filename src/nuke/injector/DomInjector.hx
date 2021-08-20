package nuke.injector;

import js.Browser;
import js.html.CSSStyleSheet;
import js.html.StyleElement;

/**
  Note: this injector is slower, but WILL allow you to inspect things
  in the dev tools.
**/
class DomInjector implements Injector {
  final el:StyleElement;
  public final sheet:CSSStyleSheet;

  public function new(?el) {
    this.el = if (el != null) el else Tools.getStyleEl();
    sheet = cast this.el.sheet;
  }
 
  public function insert(rule:String, index:Int) {
    el.insertBefore(
      Browser.document.createTextNode(rule),
      el.childNodes[index]
    );
    return 1;
  }

  public function toString() {
    return el.innerHTML;
  }
}
