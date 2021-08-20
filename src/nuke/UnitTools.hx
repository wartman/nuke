package nuke;

class UnitTools {
  public inline static function px(value:Float) {
    return '${value}px';
  }

  public inline static function pct(value:Float) {
    return '${value}%';
  }

  public inline static function em(value:Float) {
    return '${value}em';
  }

  public inline static function rem(value:Float) {
    return '${value}rem';
  }

  public inline static function vh(value:Float) {
    return '${value}vh';
  }

  public inline static function vw(value:Float) {
    return '${value}vw';
  }

  public inline static function vMin(value:Float) {
    return '${value}vmin';
  }

  public inline static function vMax(value:Float) {
    return '${value}vmax';
  }

  public inline static function deg(value:Float) {
    return '${value}deg';
  }

  public inline static function sec(value:Float) {
    return '${value}s';
  }

  public inline static function ms(value:Float) {
    return '${value}ms';
  }

  public inline static function fr(value:Float) {
    return '${value}fr';
  }

  public inline static function add(a:String, b:String) {
    return 'calc($a + $b)';
  }
  
  public inline static function sub(a:String, b:String) {
    return 'calc($a - $b)';
  }

  public inline static function mult(a:String, b:String) {
    return 'calc($a * $b)';
  }
  
  public inline static function div(a:String, b:String) {
    return 'calc($a / $b)';
  }
}