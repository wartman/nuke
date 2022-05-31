package nuke;

class Theme {
  public macro static function global(props) {
    return nuke.internal.ThemeGenerator.generateRootCustomProperties(props);
  }

  public macro static function define(props) {
    return nuke.internal.ThemeGenerator.generateCustomPropertyAtoms(props);
  }

  public macro static function set(name, value) {
    return nuke.internal.ThemeGenerator.generateRootCustomProperties({
      expr: EObjectDecl([
        { field: switch name.expr {
          case EConst(CIdent(s)) | EConst(CString(s, _)): s;
          default: haxe.macro.Context.error('Expected a string', name.pos);
        }, expr: value }
      ]),
      pos: value.pos
    });
  }

  // @todo: Currently this method is NOT statically extractable.
  public macro static function get(name, ?def) {
    var params = switch def {
      case null | { expr:EConst(CIdent('null')), pos: _ } : [name];
      default: [name, def];
    }
    return nuke.internal.Generator.extractCustomProperty(params, name.pos);
  }
}
