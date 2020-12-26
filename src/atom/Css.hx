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

class Css {
  public static macro function atoms(e) {
    return atom.CssBuilder.generateAtoms(e);
  }
  
  public static macro function rule(e) {
    var name = haxe.macro.TypeTools.toString(haxe.macro.Context.getLocalType());
    var min = haxe.macro.PositionTools.getInfos(e.pos).min;
    var sel = getKey(name + min, 'css');
    var css = atom.CssBuilder.generateString('.' + sel, e);
    return macro {
      Engine.getInstance().add($v{sel}, ${css});
      new atom.ClassName($v{sel});
    }
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

  public static function createChildAtom(selector:String, css:String) {
    var key = getKey(css + selector);
    Engine.getInstance().add(key, '.$key $selector {$css}');
    return new ClassName(key);
  }

  static function createGlobal(css:String) {
    var key = getKey(css);
    Engine.getInstance().add(key, '@media all { $css }');
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
    var key = getKey(properties + query);

    Engine.getInstance().add(key, '@media $query { .$key { $properties } }');

    return new ClassName(key);
  }

  static function getKey(css:String, prefix:String = 'a') {
    return '_${prefix}-${css.hash().hex()}';
  }
}
