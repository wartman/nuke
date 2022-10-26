package nuke.internal;

import haxe.macro.Expr;
import haxe.macro.Context;
import nuke.internal.Parser.generateCssPropertyName;

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

function generateMediaQueryProperties(query:Expr, props:Expr) {
  var mediaQuery = Generator.generateMediaQuery(query);
  return generateSelectorProperties(mediaQuery, {
    expr: EObjectDecl([
      { 
        field: ':root',
        expr: props
      }
    ]),
    pos: props.pos
  });
}

function generateSelectorProperties(selector:String, props:Expr) {
  return switch props.expr {
    case EObjectDecl(fields):
      var expr:Expr = {
        expr: EObjectDecl([
          { 
            field: selector,
            expr: {
              expr: EObjectDecl(flatten(null, fields)),
              pos: props.pos
            }
          }
        ]),
        pos: props.pos
      };
      return macro nuke.Css.global(${expr});
    default:
      Context.error('Expected an object', props.pos);
  }
}

function exprToVarName(expr:Expr) {
  return switch expr.expr {
    case EField(e, field):
      return exprToVarName(e) + '-' + generateCssPropertyName(field);
    case EConst(CIdent(s)) | EConst(CString(s, _)):
      s = generateCssPropertyName(s);
      if (s.startsWith('--')) return s;
      return '--' + s;
    default:
      Context.error('Invalid expression', expr.pos);
      null;
  }
}

private function flatten(prefix:Null<String>, props:Array<ObjectField>) {
  var out:Array<ObjectField> = [];

  for (prop in props) switch prop.field {
    case ':root': switch prop.expr.expr {
      case EObjectDecl(fields):
        var props = flatten(null, fields);
        out.push({
          field: ':root',
          expr: {
            expr: EObjectDecl(props),
            pos: prop.expr.pos
          }
        });
      default:
        Context.error('Invalid expression', prop.expr.pos);
    }
    default:
      var field = generateCssPropertyName(prop.field);
      var name = prefix != null ? prefix + '-' + field : '--' + field;
      switch prop.expr.expr {
        case EObjectDecl(fields):
          out = out.concat(flatten(name, fields));
        default:
          out.push({ field: name, expr: prop.expr });
    }
  }

  return out;
}
