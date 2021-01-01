package atom;

using atom.Hash;
using StringTools;

enum abstract MediaType(String) to String {
  var All = 'all';
  var Print = 'print';
  var Screen = 'screen';
  var Speech = 'speech';
}

typedef MediaQueryOptions = {
  @:optional public final type:MediaType;
  @:optional public final maxWidth:CssUnit;
  @:optional public final minWidth:CssUnit;
  // etc
}

enum SelectorType {
  SelChild(selector:String);
  SelPsuedo(psuedo:String);
  SelAtRule(rule:String, ?selector:String);
}

class Css {
  public static macro function atoms(e) {
    return atom.CssBuilder.generateAtoms(e);
  }
  
  public static macro function rule(e) {
    // @todo: move this all into CssBuilder?
    var name = haxe.macro.TypeTools.toString(haxe.macro.Context.getLocalType());
    var min = haxe.macro.PositionTools.getInfos(e.pos).min;
    var sel = getKey(name + min, 'css');
    var css = atom.CssBuilder.generateString('.' + sel, e);
    return atom.CssBuilder.generateRule(sel, css, e.pos);
  }

  public static macro function injectGlobalCss(e) {
    var css = atom.CssBuilder.generateString(null, e);
    return macro @:privateAccess atom.Css.createGlobal(${css});
  }

  public static function createAtom(css:String) {
    var key = getKey(css);
    Engine.getInstance().add(key, '.$key {$css}');
    return new ClassName(key);
  }

  public static function createChildAtom(selector:SelectorType, css:String) {
    var key = getKey(css + selector);
    trace(css + selector);

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
  
  public static function mediaQuery(options:MediaQueryOptions, name:String, value:CssValue) {
    var selector:Array<String> = [];
    if (options.type != null) 
      selector.push(options.type);
    if (options.maxWidth != null) 
      selector.push('(max-width: ${options.maxWidth.toString()})');
    if (options.minWidth != null) 
      selector.push('(min-width: ${options.minWidth.toString()})');

    var properties = '${name}:${value};';
    var query = selector.join(' and ');
  
    return createChildAtom(SelAtRule('@media $query'), properties);
  }

  static function getKey(css:String, prefix:String = 'a') {
    return '_${prefix}${css.hash().hex()}';
  }
}
