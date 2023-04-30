package nuke.internal;

import haxe.ds.Option;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassField;
import nuke.internal.UnitGenerator.generateUnitFromProperty;

using haxe.macro.Tools;

function extractStaticValue(value:Expr):Option<String> {
  return switch value.expr {
    case EConst(CIdent(name)):
      var local = Context.getLocalClass().get();
      var f = local.findField(name, true);

      if (f != null && f.isFinal) {
        return switch f.expr().expr {
          case TConst(TString(s)): Some(s);
          case TConst(TInt(s)): Some(Std.string(s));
          case TConst(TFloat(s)): Some(Std.string(s));
          default: None;
        }
      }
      
      None;
    case EParenthesis(e): extractStaticValue(e);
    case EConst(CString(s, _)): Some(s);
    case EConst(CInt(s)): Some(Std.string(s));
    case EConst(CFloat(s)): Some(Std.string(s));
    case EArrayDecl(exprs): mergeList(exprs, ' ');
    case ECall(e, params): switch e.expr {
      // Note: we need to handle this manually to ensure that generated
      // properties can be extracted. This may just mean we need to
      // find a better way to detect if a value is static.
      case EField(a, b): switch a.expr {
        default: switch generateUnitFromProperty(a, b) {
          case Some(e): extractStaticValue(e);
          case None: None;
        }
      }
      default: None;
    }
    case EField(a, b): switch getField(a, b, value.pos) {
      case Some(f): switch f.expr().expr {
        case TConst(TString(s)): Some(s);
        case TConst(TInt(s)): Some(Std.string(s));
        case TConst(TFloat(s)): Some(Std.string(s));
        default: None;
      }
      case None: None;
    }
    case EBinop(op, e1, e2): switch [ extractStaticValue(e1), extractStaticValue(e2) ] {
      case [ Some(v1), Some(v2) ]: switch op {
        case OpAdd: Some('calc($v1 + $v2)');
        case OpSub: Some('calc($v1 - $v2)');
        case OpMult: Some('calc($v1 * $v2)');
        case OpDiv: Some('calc($v1 / $v2)');
        default: None;
      }
      default: None;
    }
    default: None;
  }
}

function mergeList(items:Array<Expr>, join:String):Option<String> {
  var out:Array<String> = [];
  for (expr in items) switch extractStaticValue(expr) {
    case Some(v): out.push(v);
    case None: return None;
  }
  return Some(out.join(join));
}

private function getField(a:Expr, name:String, pos):Option<ClassField> {
  var typeName = getTypePathFromExpr(a, pos);
  if (typeName == null) return None;
  if (typeName.indexOf('.') < 0) {
    typeName = getTypePath(typeName, Context.getLocalImports());
  }
  var type = try {
    Context.getType(typeName).getClass();
  } catch (_:String) {
    return None;
  }
  var f = type.findField(name, true);
  if (f == null) {
    Context.error('The field ${typeName}.${name} does not exist', pos);
  }
  if (!f.isFinal) {
    return None;
  }
  return Some(f);
}

private function getTypePathFromExpr(e:Expr, pos):String {
  return switch e.expr {
    case EField(a, b): 
      getTypePathFromExpr(a, pos) + '.' + b;
    case EConst(CIdent(s)): 
      s;
    default:
      null;
  }
}

private function getTypePath(name:String, imports:Array<ImportExpr>):String {
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
