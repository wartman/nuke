package atom;

using atom.Hash;
using StringTools;

enum SelectorType {
  SelChild(selector:String);
  SelPsuedo(psuedo:String);
  SelAtRule(rule:String, ?selector:String);
}

class Css {
  public static macro function atoms(e) {
    return CssBuilder.generateAtoms(e);
  }
  
  public static macro function rule(e) {
    var sel = getKey(CssBuilder.generatePositionBasedId(e), 'css');
    var css = CssBuilder.generateString('.' + sel, e);
    return CssBuilder.generateRule(sel, css, e.pos);
  }

  public static macro function injectGlobalCss(e) {
    var css = CssBuilder.generateString(null, e);
    return macro @:privateAccess atom.Css.createGlobal(${css});
  }

  public static macro function mediaQueryAtoms(query, e) {
    var query = CssBuilder.generateMediaQuery(query);
    return CssBuilder.generateAtoms({
      expr: EObjectDecl([
        { field: query, expr: e }
      ]),
      pos: e.pos
    });
  }

  public static macro function mediaQueryRule(query, e) {
    var query = CssBuilder.generateMediaQuery(query);
    var sel = getKey(CssBuilder.generatePositionBasedId(e), 'css');
    var css = CssBuilder.generateString('.' + sel, {
      expr: EObjectDecl([
        { field: query, expr: e }
      ]),
      pos: e.pos
    });
    return CssBuilder.generateRule(sel, css, e.pos);
  }

  public static function createAtom(css:String) {
    var key = getKey(css);
    Engine.getInstance().add(key, '.$key {$css}');
    return new ClassName(key);
  }

  public static function createChildAtom(selector:SelectorType, css:String) {
    var key = getKey(css + selector);

    switch selector {
      case SelChild(selector) if (selector.startsWith(':')): // bit of a hack
        Engine.getInstance().add(key, '.$key$selector {$css}');
      case SelChild(selector):
        Engine.getInstance().add(key, '.$key $selector {$css}');
      case SelPsuedo(psuedo):
        Engine.getInstance().add(key, '.$key$psuedo {$css}');
      case SelAtRule(r, null):
        Engine.getInstance().add(key, '$r { .$key {$css} }');
      case SelAtRule(r, sel) if (sel.startsWith(':')): // bit of a hack
        Engine.getInstance().add(key, '$r { .$key$sel {$css} }');
      case SelAtRule(r, sel):
        Engine.getInstance().add(key, '$r { .$key $sel {$css} }');
    }
    
    return new ClassName(key);
  }

  static function createGlobal(css:String) {
    var key = getKey(css);
    Engine.getInstance().add(key, '@media all {$css}');
    return new ClassName(key);
  }

  static function getKey(css:String, prefix:String = 'a') {
    return '_${prefix}${css.hash().hex()}';
  }
}
