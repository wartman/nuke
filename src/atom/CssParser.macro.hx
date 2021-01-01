package atom;

import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;
using haxe.macro.Tools;

enum CssExprDef {
  CssRule(selector:String, children:Array<CssExpr>);
  CssChildren(children:Array<CssExpr>);
  CssWrapper(wrapper:String, children:Array<CssExpr>);
  CssAtom(expr:Expr);
}

typedef CssExpr = {
  expr:CssExprDef,
  pos:Position
}

class CssParser {
  static final ucase:EReg = ~/[A-Z]/g;
  
  public static function parse(e:Expr) {
    return parseRoot(e, false);
  }

  public static function parseStatic(e:Expr) {
    return parseRoot(e, true);
  }

  public static function parseRoot(e:Expr, isStatic:Bool):Array<CssExpr> {
    var exprs:Array<CssExpr> = [];
    switch e.expr {
      case EObjectDecl(fields) if (fields.length > 0):
        for (f in fields) exprs.push(parseStmt(f.field, f.expr, isStatic));
      case EConst(CString(_, _)):
        exprs.push({ expr: CssAtom(e), pos: e.pos });
      case EBlock(_) | EObjectDecl(_):
        // skip
      default:
        Context.error('Should be an object', e.pos);
    }
    return exprs;
  }

  public static function parseStmt(name:Null<String>, e:Expr, isStatic:Bool):CssExpr {
    var exprs:Array<CssExpr> = [];
    switch e.expr {
      case EObjectDecl(fields) if (name.startsWith('@') || name.contains('&') || name.startsWith(':')):
        exprs.push(parseWrappedRule(name, fields, e.pos, isStatic));
      case EObjectDecl(fields) if (fields.length > 0):
        exprs.push(parseRule(name, fields, e.pos, isStatic));
      case EBlock(_) | EObjectDecl(_):
        // skip
      default:
        exprs.push(parseProperty(name, e, isStatic));
    }
    return if (exprs.length == 1) exprs[0] else { expr: CssChildren(exprs), pos: e.pos };
  }

  public static function parseRule(selector:String, props:Array<ObjectField>, pos:Position, isStatic:Bool):CssExpr {
    return { expr: CssRule(selector, [ 
      for (f in props) parseStmt(f.field, f.expr, isStatic)
    ]), pos: pos };
  }

  public static function parseWrappedRule(selector:String, props:Array<ObjectField>, pos:Position,  isStatic:Bool):CssExpr {
    return { expr: CssWrapper(selector, [ 
      for (f in props) parseStmt(f.field, f.expr, isStatic)
    ]), pos: pos };
  }

  public static function parseProperty(name:String, e:Expr, isStatic:Bool):CssExpr {
    var cssName = generateCssPropertyName(name);
    return  { expr: if (isStatic) {
      CssAtom(macro @:pos(e.pos) $v{cssName + ':' + extractStaticValue(e) + ';'});
    } else {
      CssAtom(macro @:pos(e.pos) $v{cssName} + ':' + (${e}:atom.CssValue) + ';');
    }, pos: e.pos };
  }

  static function generateCssPropertyName(key:String) {
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
  
  // @todo: this could use A LOT OF cleanup.
  static function extractStaticValue(value:Expr):String {
    if (Context.unify(Context.typeof(value), Context.getType('atom.CssUnit'))) {
      switch value.expr {
        case EConst(CIdent('Auto')): return 'auto';
        case EConst(CIdent('None')): return '0';
        case EConst(CIdent(name)):
          var local = Context.getLocalClass().get();
          var f = local.findField(name, true);
          if (f != null && f.isFinal) {
            return extractCssUnitValue(Context.getTypedExpr(f.expr()));
          } else {
            Context.error('A static value is requried', value.pos);
          }
        case EField(a, b):
          return extractCssUnitValue(Context.getTypedExpr(getField(a, b, value.pos).expr()));
        default: 
          return extractCssUnitValue(value);
      }
    }

    return switch value.expr {
      case EConst(CIdent(name)):
        var local = Context.getLocalClass().get();
        var f = local.findField(name, true);
        if (f != null && f.isFinal) {
          return switch f.expr().expr {
            case TConst(TString(s)): s;
            case TConst(TInt(s)): Std.string(s);
            case TConst(TFloat(s)): Std.string(s);
            default: Context.error('A static value is requried', value.pos);
          }
        }
        Context.error('A static value is requried', value.pos);
        null;
      case EConst(CString(s, _)): s;
      case EConst(CInt(s)): Std.string(s);
      case EConst(CFloat(s)): Std.string(s);
      case EField(a, b): switch getField(a, b, value.pos).expr().expr {
        case TConst(TString(s)): s;
        case TConst(TInt(s)): Std.string(s);
        case TConst(TFloat(s)): Std.string(s);
        default: Context.error('A static value is requried', value.pos);
      }
      default: Context.error('A static value is requried', value.pos);
    }
  }

  static function getTypePathFromExpr(e:Expr, pos):String {
    return switch e.expr {
      case EField(a, b): 
        getTypePathFromExpr(a, pos) + '.' + b;
      case EConst(CIdent(s)): 
        s;
      default:
        Context.error('Invalid expression', pos);
        null;
    }
  }

  static function getField(a:Expr, name:String, pos) {
    var typeName = getTypePathFromExpr(a, pos);
    if (typeName.indexOf('.') < 0) {
      typeName = getTypePath(typeName, Context.getLocalImports());
    }
    var type = try {
      Context.getType(typeName).getClass();
    } catch (e:String) {
      Context.error('The type ${typeName} was not found', pos);
    }
    var f = type.findField(name, true);
    if (f == null) {
      Context.error('The field ${typeName}.${name} does not exist', pos);
    }
    if (!f.isFinal) {
      Context.error('Fields must be static and final', pos);
    }
    return f;
  }
  
  // @todo: There HAS to be a better way to do this? It may just not be 
  //        worth the hassle.
  static function extractCssUnitValue(value:Expr) return switch value.expr {
    case ECall(unit, params) if (params.length > 0):
      var str = extractStaticValue(params[0]);
      var suffix = switch unit.expr {
        case EConst(CIdent(s)): switch s {
          case 'Pct': '%';
          case 'Sec': 's';
          case 'Num': '';
          default: s.toLowerCase();
        }
        case EField(_): switch getTypePathFromExpr(unit, value.pos).split('.').pop() {
          case 'Pct': '%';
          case 'Sec': 's';
          case 'Num': '';
          case s: s.toLowerCase();
        }
        default: throw 'assert';
      }
      str + suffix;
    case EConst(CIdent('Auto')): 'auto';
    case EConst(CIdent('None')): '0';
    case ECall(unit, _):
      switch unit.expr {
        case EConst(CIdent('Auto')): 'auto';
        case EConst(CIdent('None')): '0';
        case EField(_): switch getTypePathFromExpr(unit, value.pos).split('.').pop() {
          case 'Auto': 'auto';
          case 'None': '0';
          default: throw 'assert';
        }
        default: throw 'assert';
      }
    default:
      ''; 
  }

  static function getTypePath(name:String, imports:Array<ImportExpr>):String {
    // check imports
    for (i in imports) switch i.mode {
      case IAsName(n):
        if (n == name) {
          var name = i.path[i.path.length - 1].name; 
          var pack = [ for (index in 0...i.path.length-1) i.path[index].name ];
          return pack.concat([ name ]).join('.');
        }
      default:
        var n = i.path[i.path.length - 1].name;
        if (n == name) {
          var pack = [ for (index in 0...i.path.length-1) i.path[index].name ];
          return pack.concat([ name ]).join('.');
        }
    }
    // If not found, assume local or full type path.
    return name;
  }
}