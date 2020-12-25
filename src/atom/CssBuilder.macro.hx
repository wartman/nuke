package atom;

import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;
using haxe.macro.Tools;

class CssBuilder {
  static final ucase:EReg = ~/[A-Z]/g;

  public static function generate(e:Expr):Expr {
    return switch e.expr {
      case EObjectDecl(decls) if (decls.length >= 0):
        return macro @:pos(e.pos) ([ $a{parse(decls)} ]:atom.ClassName);
      case EBlock(_) | EObjectDecl(_):
        macro null;
      default:
        Context.error('Should be an object', e.pos);
    }
  }

  public static function generateString(e:Expr):Expr {
    return switch e.expr {
      case EObjectDecl(decls) if (decls.length >= 0):
        return parseToString(decls);
      case EBlock(_) | EObjectDecl(_):
        macro null;
      default:
        Context.error('Should be an object', e.pos);
    }
  }

  static function parseToString(rules:Array<ObjectField>, ?selector:String) {
    var exprs:Array<Expr> = [];
    for (rule in rules) switch rule.expr.expr {
      case EObjectDecl(fields):
        var key = rule.field;
        switch key.charAt(0) {
          case '@':
            // noop
          default:
            var sel = if (selector != null) selector + ' ' + rule.field else rule.field;
            exprs.push(macro $v{sel} + ' {' + ${parseToString(fields, sel)} + '}');
        }
      default:
        var key = prepareKey(rule.field);
        var e = rule.expr;
        exprs.push(macro @:pos(e.pos) $v{key} + ':' + (${e}:atom.CssValue) + ';');
    }
    return macro [ $a{exprs} ].join('\n');
  }

  static function parse(rules:Array<ObjectField>, ?selector:String) {
    var exprs:Array<Expr> = [];
    for (rule in rules) switch rule.expr.expr {
      case EObjectDecl(fields):
        var key = rule.field;
        switch key.charAt(0) {
          case '@':
            // noop
          default:
            var sel = if (selector != null) selector + ' ' + rule.field else rule.field;
            exprs = exprs.concat(parse(fields, sel));
        }
      default:
        var key = prepareKey(rule.field);
        var e = rule.expr;
        if (selector == null)
          exprs.push(macro @:pos(e.pos) atom.Css.atomRule($v{key}, (${e}:atom.CssValue)));
        else 
          exprs.push(macro @:pos(e.pos) atom.Css.childAtomRule($v{selector}, $v{key}, (${e}:atom.CssValue)));
    }
    return exprs;
  }

  static function prepareKey(key:String) {
    return [ for (i in 0...key.length)
      if (ucase.match(key.charAt(i))) {
        if (i == 0)
          key.charAt(i).toLowerCase()
        else 
          '-' + key.charAt(i).toLowerCase();
      } else {
        key.charAt(i);
      } 
    ].join('');
  }
}