package nuke.internal;

import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;

function generateCustomPropertyAtoms(props:Expr) {
  return switch props.expr {
    case EObjectDecl(fields):
      return macro nuke.Css.atoms(${ {
        expr: EObjectDecl(flatten(null, fields)),
        pos: props.pos
      } });
    default:
      Context.error('Expected an object', props.pos);
  }
}

function generateRootCustomProperties(props:Expr) {
  return switch props.expr {
    case EObjectDecl(fields):
      return macro nuke.Css.global({
        ':root': ${ {
          expr: EObjectDecl(flatten(null, fields)),
          pos: props.pos
        } }
      });
    default:
      Context.error('Expected an object', props.pos);
  }  
}

function exprToVarName(expr:Expr) {
  return switch expr.expr {
    case EField(e, field):
      return exprToVarName(e) + '-' + field;
    case EConst(CIdent(s)) | EConst(CString(s, _)):
      if (s.startsWith('--')) return s;
      return '--' + s;
    default:
      Context.error('Invalid expression', expr.pos);
      null;
  }
}

private function flatten(prefix:Null<String>, props:Array<ObjectField>) {
  var out:Array<ObjectField> = [];

  for (prop in props) {
    var name = prefix != null ? prefix + '-' + prop.field : '--' + prop.field;
    switch prop.expr.expr {
      case EObjectDecl(fields):
        out = out.concat(flatten(name, fields));
      default:
        out.push({ field: name, expr: prop.expr });
    }
  }

  return out;
}
