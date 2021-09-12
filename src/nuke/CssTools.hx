package nuke;

class CssTools {
  public macro static function px(value:haxe.macro.Expr.ExprOf<Float>) {
    return nuke.internal.UnitGenerator.generateUnit(value, 'px');
  }

  public macro static function pct(value:haxe.macro.Expr.ExprOf<Float>) {
    return nuke.internal.UnitGenerator.generateUnit(value, '%');
  }

  public macro static function em(value:haxe.macro.Expr.ExprOf<Float>) {
    return nuke.internal.UnitGenerator.generateUnit(value, 'em');
  }

  public macro static function rem(value:haxe.macro.Expr.ExprOf<Float>) {
    return nuke.internal.UnitGenerator.generateUnit(value, 'rem');
  }

  public macro static function vh(value:haxe.macro.Expr.ExprOf<Float>) {
    return nuke.internal.UnitGenerator.generateUnit(value, 'vh');
  }

  public macro static function vw(value:haxe.macro.Expr.ExprOf<Float>) {
    return nuke.internal.UnitGenerator.generateUnit(value, 'vw');
  }

  public macro static function vMin(value:haxe.macro.Expr.ExprOf<Float>) {
    return nuke.internal.UnitGenerator.generateUnit(value, 'vmin');
  }

  public macro static function vMax(value:haxe.macro.Expr.ExprOf<Float>) {
    return nuke.internal.UnitGenerator.generateUnit(value, 'vmax');
  }

  public macro static function deg(value:haxe.macro.Expr.ExprOf<Float>) {
    return nuke.internal.UnitGenerator.generateUnit(value, 'deg');
  }

  public macro static function sec(value:haxe.macro.Expr.ExprOf<Float>) {
    return nuke.internal.UnitGenerator.generateUnit(value, 's');
  }

  public macro static function ms(value:haxe.macro.Expr.ExprOf<Float>) {
    return nuke.internal.UnitGenerator.generateUnit(value, 'ms');
  }

  public macro static function fr(value:haxe.macro.Expr.ExprOf<Float>) {
    return nuke.internal.UnitGenerator.generateUnit(value, 'fr');
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
