package nuke.injector;

import js.Browser.document;
import js.html.StyleElement;

class Tools {
  static final styleId:String = '__nuke__';

  public static function getStyleEl():StyleElement {
    return switch document.getElementById(styleId) {
      case null:
        var el = document.createStyleElement();
        el.id = styleId;
        document.head.appendChild(el);
        el;
      case el: cast el;
    }
  }
}