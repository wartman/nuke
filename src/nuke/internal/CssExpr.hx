package nuke.internal;

import haxe.macro.Expr;

typedef CssExpr = {
  expr:CssExprDef,
  pos:Position
}

enum CssExprDef {
  CssRule(selector:String, children:Array<CssExpr>);
  CssChildren(children:Array<CssExpr>);
  CssWrapper(wrapper:String, children:Array<CssExpr>);
  CssAtom(property:String, value:Expr);
  CssRaw(css:Expr);
}
