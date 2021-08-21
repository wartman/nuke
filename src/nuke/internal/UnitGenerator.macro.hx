package nuke.internal;

import haxe.ds.Option;
import haxe.macro.Expr;
import nuke.internal.StaticExtractor.extractStaticValue;

function generateUnit(expr:Expr, suffix:String) {
  return switch extractStaticValue(expr) {
    case Some(unit): return macro @:pos(expr.pos) $v{'${unit}${suffix}'};
    case None: return macro @:pos(expr.pos) $expr + $v{suffix};
  }
}

function generateUnitfromProperty(expr:Expr, field:String):Option<Expr> {
  return switch field {
    case 'px' | 'em' | 'rem' | 'vh' | 'vw' | 'ms' | 'fr' | 'deg':
      Some(generateUnit(expr, field));
    case 'vMin':
      Some(generateUnit(expr, 'vmin'));
    case 'vMax':
      Some(generateUnit(expr, 'vmax'));
    case 'pct':
      Some(generateUnit(expr, '%'));
    case 'sec':
      Some(generateUnit(expr, 's'));
    default:
      None;
  }
}
