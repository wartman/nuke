package atom;

abstract CssValue(String) to String from String {
  @:from public static function ofCssUnitArray(values:Array<CssUnit>) {
    return new CssValue(values.map(v -> v.toString()).join(' '));
  }

  @:from public static function compound(values:Array<CssValue>) {
    return new CssValue(values.join(' '));
  }

  public static function list(values:Array<CssValue>) {
    return new CssValue(values.join(', '));
  }

  @:from public inline static function ofInt(value:Int) {
    return new CssValue(Std.string(value));
  }

  @:from public inline static function ofFloat(value:Float) {
    return new CssValue(Std.string(value));
  }

  @:from public inline static function ofCssUnit(unit:CssUnit) {
    return new CssValue(switch unit {
      case None: '0';
      case Num(value): Std.string(value);
      default: unit.toString();
    });
  }

  public inline function new(value) {
    this = value;
  }
}