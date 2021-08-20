package nuke;

using StringTools;

abstract ClassName(String) to String {
  @:from static function ofString(s:String):ClassName {
    return if (s == null) null else new ClassName(s.trim());
  }

  @:from public static function ofMap(parts:Map<String, Bool>) {
    return ofArray([ 
      for (name => isValid in parts) if (isValid) ofString(name)
    ]);
  }

  @:from public static function ofDynamicAccess(parts:haxe.DynamicAccess<Bool>) {
    return ofArray([
      for (name => isValid in parts) if (isValid) ofString(name)
    ]);
  }

  @:from public static function ofArray(parts:Array<String>) {
    return new ClassName(parts.map(ofString).join(' '));
  }

  @:from public static function ofAtoms(parts:Array<Atom>) {
    return new ClassName(parts.map(a -> a.getClassName()).join(' '));
  }

  inline public function new(s:String) {
    this = s;
  }

  public function with(other:ClassName) {
    return new ClassName(switch [this, (other:String)] {
      case [null, v] | [v, null]: v;
      case [a, b]: '$a $b';
    });
  }
}
