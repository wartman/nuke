package nuke.internal;

import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

function parse(e:Expr):Array<CssExpr> {
  var exprs:Array<CssExpr> = [];

  switch e.expr {
    case EObjectDecl(fields) if (fields.length > 0):
      for (f in fields) exprs.push(parseStmt(f.field, f.expr));
    case EConst(CString(_, _)):
      exprs.push({ expr: CssRaw(e), pos: e.pos });
    case EBlock(_) | EObjectDecl(_):
      // skip
    default:
      Context.error('Should be an object', e.pos);
  }

  return exprs;
}

private final ucase:EReg = ~/[A-Z]/g;

function generateCssPropertyName(key:String) {
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

private function parseStmt(name:Null<String>, e:Expr):CssExpr {
  var exprs:Array<CssExpr> = [];
  switch e.expr {
    case EObjectDecl(fields) if (name.startsWith('@') || name.contains('&') || name.startsWith(':')):
      exprs.push(parseWrappedRule(name, fields, e.pos));
    case EObjectDecl(fields) if (fields.length > 0):
      exprs.push(parseRule(name, fields, e.pos));
    case EBlock(_) | EObjectDecl(_):
      // skip
    default:
      exprs.push(parseProperty(name, e));
  }
  return if (exprs.length == 1) exprs[0] else { expr: CssChildren(exprs), pos: e.pos };
}

private function parseRule(selector:String, props:Array<ObjectField>, pos:Position):CssExpr {
  return { expr: CssRule(selector, [ 
    for (f in props) parseStmt(f.field, f.expr)
  ]), pos: pos };
}

private function parseWrappedRule(selector:String, props:Array<ObjectField>, pos:Position):CssExpr {
  return { expr: CssWrapper(selector, [ 
    for (f in props) parseStmt(f.field, f.expr)
  ]), pos: pos };
}

private function parseProperty(name:String, e:Expr):CssExpr {
  var cssName = generateCssPropertyName(name);
  return  { 
    expr: CssAtom(cssName, e),
    pos: e.pos 
  };
}
