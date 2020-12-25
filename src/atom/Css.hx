package atom;

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

// @todo: This API is confusing.
class Css {
  public static macro function atoms(e) {
    return atom.CssBuilder.generate(e);
  }
  
  public static macro function rule(e) {
    var css = atom.CssBuilder.generateString(e);
    return macro @:privateAccess atom.Css.create(${css});
  }

  public static macro function globalRule(e) {
    var css = atom.CssBuilder.generateString(e);
    return macro @:privateAccess atom.Css.createGlobal(${css});
  }

  public inline static function atomRule(name:String, value:CssValue) {
    return create('${name}:${value};');
  }

  public static function childAtomRule(selector:String, name:String, value:String) {
    var properties = '${name}:${value};';
    var key = getKey(properties + selector);
    Engine.getInstance().add(key,  '.$key $selector { $properties }');
    return new ClassName(key);
  }

  static function create(css:String) {
    var key = getKey(css);
    Engine.getInstance().add(key, '.$key { $css }');
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

  static function getKey(css:String) {
    return '_a-${Hash.hash(css)}';
  }
}
