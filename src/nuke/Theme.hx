package nuke;

class Theme {
  /**
    Define theme properties for the root scope.
  **/
  public macro static function global(props) {
    return nuke.internal.ThemeGenerator.generateRootCustomProperties(props);
  }

  /**
    Define theme properties for the given slector. Note that this will NOT
    return a ClassName -- use `Theme.define` for that behavior. This is 
    for creating rules in the global scope (for example, `body.dark-theme`).
  **/
  public macro static function select(selector, props) {
    var sel = switch selector.expr {
      case EConst(CString(s, _)): s;
      default: haxe.macro.Context.error('Expected a string', selector.pos);
    }
    return nuke.internal.ThemeGenerator.generateSelectorProperties(sel, props);
  }

  /**
    Define theme properties for the given media query (such as `prefers-reduced-motion`).
  **/
  public macro static function mediaQuery(query, props) {
    return nuke.internal.ThemeGenerator.generateMediaQueryProperties(query, props);
  }

  /**
    Define atomic theme properties. This method returns a ClassName. 
  **/
  public macro static function define(props) {
    return nuke.internal.ThemeGenerator.generateCustomPropertyAtoms(props);
  }

  /**
    Define a single theme property. This method returns a ClassName. 
  **/
  public macro static function defineProperty(name, value) {
    return nuke.internal.ThemeGenerator.generateCustomPropertyAtoms({
      expr: EObjectDecl([
        { field: switch name.expr {
          case EConst(CIdent(s)) | EConst(CString(s, _)): s;
          default: haxe.macro.Context.error('Expected a string', name.pos);
        }, expr: value }
      ]),
      pos: value.pos
    });
  }

  /**
    Get a reference to a theme property name.
  **/
  public macro static function property(name, ?def) {
    var varName = nuke.internal.ThemeGenerator.exprToVarName(name);
    var name = macro $v{varName};
    var params = switch def {
      case null | { expr:EConst(CIdent('null')), pos: _ } : [name];
      default: [name, def];
    }
    return nuke.internal.Generator.prepareValue(
      macro @:pos(name.pos) theme($a{params})
    );
  }
}
