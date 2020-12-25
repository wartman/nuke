package atom;

@:using(atom.CssUnit.CssUnitTools)
enum CssUnit {
  None;
  Auto;
  Num(value:Float);
  Px(value:Float);
  Pct(value:Float);
  Em(value:Float);
  Rem(value:Float);
  Vh(value:Float);
  Vw(value:Float);
  VMin(value:Float);
  VMax(value:Float);
  Deg(value:Float);
  Sec(value:Float);
  Ms(value:Float);
  Fr(value:Float);
}

class CssUnitTools {
  public static function toString(unit:CssUnit) {
    if (unit == null) return null;
    return switch unit {
      case None: '0';
      case Auto: 'auto';
      case Num(value): Std.string(value);
      case Px(value): '${value}px';
      case Pct(value): '${value}%';
      case Em(value): '${value}em';
      case Rem(value): '${value}rem';
      case Vh(value): '${value}vh';
      case Vw(value): '${value}vw';
      case VMin(value): '${value}vmin';
      case VMax(value): '${value}vmax';
      case Deg(value): '${value}deg';
      case Sec(value): '${value}s';
      case Ms(value): '${value}ms';
      case Fr(value): '${value}fr';
    }
  }

  public static function negate(unit:CssUnit) {
    return switch unit {
      case None | Auto: unit;
      case Num(value): Num(-value);
      case Px(value): Px(-value);
      case Pct(value): Pct(-value);
      case Em(value): Em(-value);
      case Rem(value): Rem(-value);
      case Vh(value): Vh(-value);
      case Vw(value): Vw(-value);
      case VMin(value): VMin(-value);
      case VMax(value): VMax(-value);
      case Deg(value): Deg(-value);
      case Sec(value): Sec(-value);
      case Ms(value): Ms(-value);
      case Fr(value): Fr(-value);
    }
  }
}
