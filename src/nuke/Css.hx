package nuke;

#if macro
  import nuke.internal.Parser.parse;
  import nuke.internal.Generator.generate;
  import haxe.macro.Expr;

  private function createAtoms(e:Expr) {
    var cssExprs = parse(e);
    var exprs = generate(cssExprs);
    return macro @:pos(e.pos) ([$a{exprs}]:nuke.ClassName);
  }
#end

class Css {
  public static macro function atoms(e) {
    return createAtoms(e);
  }

  public static macro function mediaQuery(query, e) {
    var mediaQuery = nuke.internal.Generator.generateMediaQuery(query);
    return createAtoms({
      expr: EObjectDecl([
        { field: mediaQuery, expr: e }
      ]),
      pos: e.pos
    });
  }
}
