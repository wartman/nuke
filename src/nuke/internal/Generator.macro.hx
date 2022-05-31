package nuke.internal;

import haxe.macro.Context;
import haxe.macro.Expr;
import nuke.internal.Hash.hash;
import nuke.internal.StaticExtractor.mergeList;
import nuke.internal.Parser.generateCssPropertyName;
import nuke.internal.StaticExtractor.extractStaticValue;

using Lambda;
using StringTools;
using nuke.internal.Prefix;

function generate(exprs:Array<CssExpr>, ?parent:String, ?atRule:String):Array<Expr> {
  return exprs.map(expr -> generateAtom(expr, parent, atRule)).flatten();
}

function generateRawCss(exprs:Array<CssExpr>):Expr {
  var css = generateRawCssExprs(exprs);
  var key = nuke.internal.Hash.hash(css); // todo: will this be slow?
  if (CssExporter.shouldExport()) {
    Engine.getInstance().addRawCss(key, css);
    return macro 0;
  }
  return macro nuke.Engine.getInstance().addRawCss($v{key}, $v{css});
}

private function generateRawCssExprs(exprs:Array<CssExpr>, ?parent:String, ?atRule:String):String {
  var out:Array<String> = [];
  function generateRawCssExpr(expr:CssExpr) switch expr.expr {
    case CssRule(selector, children):
      out.push(generateRawCssExprs(children, selector, atRule));
    case CssChildren(children):
      out.push(generateRawCssExprs(children, null, atRule));
    case CssWrapper(wrapper, children) if (wrapper.contains('&')):
      if (parent == null) {
        Context.error('Rules with "&" require a parent', expr.pos);
      }
      out.push(generateRawCssExprs(children, wrapper.replace('&', parent), atRule));
    case CssWrapper(wrapper, children) if (wrapper.startsWith(':')):
      out.push(generateRawCssExprs(children, parent != null ? parent + wrapper : wrapper, atRule));
    case CssWrapper(wrapper, children):
      // todo: handle special cases like @font-face and @keyframes
      if (atRule != null) {
        Context.error('At-rules cannot be nested', expr.pos);
      }
      if (wrapper.startsWith('@')) {
        wrapper = wrapper.substr(1);
      }
      out.push(generateRawCssExprs(children, parent, wrapper));
    case CssAtom(property, value):
      if (parent == null) {
        Context.error('Atoms require parents when generating raw css', expr.pos);
      }
      value = prepareValue(value);
      switch extractStaticValue(value) {
        case Some(value):
          var rule = '$parent{$property:$value}';
          if (atRule != null) rule = '@$atRule {$rule}';
          out.push(rule);
        case None:
          Context.error('Only static values are allowed in raw css', expr.pos);
      }
    case CssRaw(css):
      Context.error('Raw strings are not allowed when creating raw css', expr.pos);
  }
  for (expr in exprs) generateRawCssExpr(expr);
  return out.join(' ');
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
      exprs = exprs.concat(generate(
        children,
        parent != null ? parent + ' ' + selector : ' ' + selector,
        atRule
      ));
    case CssAtom(property, value):
      value = prepareValue(value);
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

private function prepareValue(expr:Expr):Expr {
  return switch expr.expr {
    case EArrayDecl(values):
      return {
        expr: EArrayDecl(values.map(prepareValue)),
        pos: expr.pos
      };
    case ECall(e, params):
      switch e.expr {
        case EConst(CIdent(name)): switch name {
          case 'theme':
            extractCustomProperty(params, e.pos);
          case 'list':
            var exprs = params.map(prepareValue);
            switch mergeList(exprs, ',') {
              case Some(v):
                macro $v{v};
              case None: 
                macro [ $a{exprs} ].join(',');
            }
          default:
            var exprs = params.map(prepareValue);
            switch mergeList(exprs, ',') {
              case Some(v): 
                name = generateCssPropertyName(name);
                var str = name + '(' + v + ')';
                return macro $v{str};
              case None:
                name = generateCssPropertyName(name);
                macro $v{name} + '(' + [ $a{exprs} ].join(',') + ')';
            }
        }
        default: expr;
      }
    default: expr;
  }
}

function extractCustomProperty(params:Array<Expr>, pos) {
  function getName(c:Constant) {
    var name = switch c {
      case CString(s, _): s;
      case CIdent(s): s;
      default: 
        Context.error('Expected a string or an identifier', pos);
    }
    
    if (!name.startsWith('--')) {
      name = '--' + name;
    }

    return name;
  }

  return switch params {
    case [ { expr: EConst(c) } ]:
      var name = getName(c);
      macro $v{'var($name)'};
    case [ { expr: EConst(c) }, expr ]:
      var name = getName(c);
      return switch extractStaticValue(expr) {
        case Some(v):
          var css = 'var($name,$v)';
          return macro $v{css};
        case None:
          var value = prepareValue(expr);
          return macro 'var(' + $v{name} + ',' + ${value} + ')';
      }
    default:
      Context.error('Too many arguments', pos);
  }
}
