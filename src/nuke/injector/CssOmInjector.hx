package nuke.injector;

import js.html.CSSStyleSheet;

class CssOmInjector implements Injector {
  public final sheet:CSSStyleSheet;

  public function new(?sheet) {
    this.sheet = if (sheet != null) sheet else cast Tools.getStyleEl().sheet;
  }

  public function insert(rule:String, index:Int) {
    return try {
      sheet.insertRule(rule, index);
    } catch (e) -1;
  }

  public function toString() {
    return [ for (rule in sheet.cssRules) rule.cssText ].join('\n');
  }
}
