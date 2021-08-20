package nuke.internal;

import haxe.ds.Option;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassField;
import nuke.internal.Hash.hash;
import nuke.internal.Parser.generateCssPropertyName;

using Lambda;
using StringTools;
using haxe.macro.Tools;
using nuke.internal.Prefix;

function generate(exprs:Array<CssExpr>, ?parent:String, ?atRule:String):Array<Expr> {
  return exprs.map(expr -> generateAtom(expr, parent, atRule)).flatten();
}

function generateMediaQuery(query:Expr):String {
  return switch query.expr {
    case EConst(CString(s, _)): 
      '@media $s'; // Todo: handle interpolation?
    
    case EObjectDecl(fields):
      var selector:Array<String> = [];

      // `type` needs to be first
      fields.sort((a, b) -> {
        if (a.field == 'type') -1;
        else if (b.field == 'type') 1;
        else 0;
      });
      
      for (f in fields) switch f.field {
        case 'type': switch f.expr.expr {
          case EConst(CString(s, _)): 
            selector.push(s);
          default:
            Context.error('Expected a string', f.expr.pos);
        }
        default:
          var name = generateCssPropertyName(f.field);
          switch extractStaticValue(f.expr) {
            case None:
              Context.error('Only static values are allowed in media queries.', f.expr.pos);
            case Some(value):
              selector.push('(${name}: ${value})');
          }
      }

      '@media ' + selector.join(' and ');
    default:
      Context.error('Expected a string or a query object', query.pos);
      '';
  }
}

private function generateAtom(expr:CssExpr, ?parent:String, ?atRule:String):Array<Expr> {
  var exprs:Array<Expr> = [];
  switch expr.expr {
    case CssChildren(children):
      exprs = exprs.concat(generate(children, parent, atRule));
    case CssWrapper(wrapper, children) if (wrapper.contains('&')):
      if (parent == null) {
        Context.error('Rules with "&" require a parent', expr.pos);
      }
      exprs = exprs.concat(generate(children, wrapper.replace('&', parent), atRule));
    case CssWrapper(wrapper, children) if (wrapper.startsWith(':')):
      exprs = exprs.concat(generate(children, parent != null ? parent + wrapper : wrapper, atRule));
    case CssWrapper(wrapper, children):
      // todo: handle special cases like @font-face and @keyframes
      if (atRule != null) {
        Context.error('At-rules cannot be nested', expr.pos);
      }
      if (wrapper.startsWith('@')) {
        wrapper = wrapper.substr(1);
      }
      exprs = exprs.concat(generate(children, parent, wrapper));
    case CssRule(selector, children):
      exprs = exprs.concat(generate(children, parent != null ? parent + ' ' + selector : ' ' + selector ));
    case CssAtom(property, value):
      function wrap(expr:Expr) {
        if (parent != null) {
          expr = macro nuke.Atom.createWrappedAtom($v{parent}, ${expr});
        }
        if (atRule != null) {
          expr = macro nuke.Atom.createAtRuleAtom($v{atRule}, ${expr});
        }
        return expr;
      }

      var expr = switch extractStaticValue(value) {
        case Some(value):
          var css = '${property}:${value}';
          var className = hash(css).withPrefix();
          if (CssExporter.shouldExport()) {
            var atom = Atom.createStaticAtom(className, css);
            if (parent != null) {
              atom = Atom.createWrappedAtom(parent, atom);
            }
            if (atRule != null) {
              atom = Atom.createAtRuleAtom(atRule, atom);
            }
            macro @:pos(expr.pos) nuke.Atom.createPrerenderedAtom($v{atom.getClassName()});
          } else {
            wrap(macro @:pos(expr.pos) nuke.Atom.createStaticAtom($v{className}, $v{css}));
          }    
        case None:
          wrap(macro @:pos(expr.pos) nuke.Atom.createAtom($v{property}, ${value}));
      }
      exprs.push(expr);

    case CssRaw(css): 
      switch extractStaticValue(css) {
        case Some(css):
          var className = hash(css).withPrefix();
          var expr = macro @:pos(expr.pos) nuke.Atom.createStaticAtom($v{className}, $v{css});
          if (parent != null) {
            expr = macro nuke.Atom.createWrappedAtom($v{parent}, ${expr});
          }
          if (atRule != null) {
            expr = macro nuke.Atom.createAtRuleAtom($v{atRule}, ${expr});
          }
          exprs.push(expr);
        case None:
          Context.error('Raw strings can only contain static values', expr.pos);
      }
  }
  return exprs;
}

private function extractStaticValue(value:Expr):Option<String> {
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
    case EConst(CString(s, _)): Some(s);
    case EConst(CInt(s)): Some(Std.string(s));
    case EConst(CFloat(s)): Some(Std.string(s));
    case EField(a, b): switch getField(a, b, value.pos) {
      case Some(f): switch f.expr().expr {
        case TConst(TString(s)): Some(s);
        case TConst(TInt(s)): Some(Std.string(s));
        case TConst(TFloat(s)): Some(Std.string(s));
        default: None;
      }
      case None:
        None;
    }
    default: None;
  }
}

private function getField(a:Expr, name:String, pos):Option<ClassField> {
  var typeName = getTypePathFromExpr(a, pos);
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
      Context.error('Invalid expression', pos);
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
