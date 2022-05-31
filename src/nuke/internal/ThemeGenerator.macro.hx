package nuke.internal;

import haxe.macro.Expr;
import haxe.macro.Context;

function generateCustomPropertyAtoms(props:Expr) {
  return switch props.expr {
    case EObjectDecl(fields):
      var customProps = fields.map(f -> {
        f.field = '--' + f.field;
        return f;
      });
      return macro nuke.Css.atoms(${ {
        expr: EObjectDecl(customProps),
        pos: props.pos
      } });
    default:
      Context.error('Expected an object', props.pos);
  }
}

function generateRootCustomProperties(props:Expr) {
  return switch props.expr {
    case EObjectDecl(fields):
      var customProps = fields.map(f -> {
        f.field = '--' + f.field;
        return f;
      });
      return macro nuke.Css.global({
        ':root': ${ {
          expr: EObjectDecl(customProps),
          pos: props.pos
        } }
      });
    default:
      Context.error('Expected an object', props.pos);
  }  
}
