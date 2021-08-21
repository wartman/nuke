package nuke.internal;

import haxe.ds.Option;
import haxe.macro.Context;
import haxe.macro.Expr;
import nuke.internal.Hash.hash;
import nuke.internal.Parser.generateCssPropertyName;
import nuke.internal.StaticExtractor.extractStaticValue;

using Lambda;
using StringTools;
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
  
  function wrap(expr:Expr) {
    if (parent != null) {
      expr = macro nuke.Atom.createWrappedAtom($v{parent}, ${expr});
    }
    if (atRule != null) {
      expr = macro nuke.Atom.createAtRuleAtom($v{atRule}, ${expr});
    }
    return macro $expr.inject();
  }

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
            atom.inject();
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
          exprs.push(wrap(expr));
        case None:
          Context.error('Raw strings can only contain static values', expr.pos);
      }
  }
  return exprs;
}
