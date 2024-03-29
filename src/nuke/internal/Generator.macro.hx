package nuke.internal;

import haxe.macro.Context;
import haxe.macro.Expr;
import nuke.internal.Hash.hash;
import nuke.internal.StaticExtractor.mergeList;
import nuke.internal.Parser.generateCssPropertyName;
import nuke.internal.StaticExtractor.extractStaticValue;
import nuke.internal.ThemeGenerator.exprToVarName;

using Lambda;
using StringTools;
using nuke.internal.Prefix;
using haxe.macro.PositionTools;

function generate(exprs:Array<CssExpr>, ?parent:String, ?atRule:String):Array<Expr> {
  return exprs.map(expr -> generateAtom(expr, parent, atRule)).flatten();
}

function generateRule(exprs:Array<CssExpr>, ?parent:String, ?atRule:String):Expr {
  var module = Context.getLocalModule();
  var pos = Context.currentPos().getInfos();
  var key = hash('${module}_${pos.min}_${pos.max}').withPrefix();
  var css = generateRawCssExprs(exprs, '.${key}');

  if (CssExporter.shouldExport()) {
    Engine.getInstance().addRawCss(key, css);
    return macro nuke.Atom.createPrerenderedAtom($v{key});
  }
  
  return macro nuke.Atom.createRawAtom($v{key}, $v{css}).inject();
}

function generateRawCss(exprs:Array<CssExpr>):Expr {
  var css = generateRawCssExprs(exprs);
  var key = hash(css);

  if (CssExporter.shouldExport()) {
    Engine.getInstance().addRawCss(key, css);
    return macro 0;
  }

  return macro nuke.Engine.getInstance().addRawCss($v{key}, $v{css});
}

private function generateRawCssExprs(exprs:Array<CssExpr>, ?parent:String, ?atRule:String):String {
  var out:Array<String> = [];
  var body:Array<String> = [];
  var media:Map<String, Array<String>> = [];

  function generateRawCssExpr(expr:CssExpr) switch expr.expr {
    case CssRule(selector, children):
      out.push(generateRawCssExprs(children, parent != null ? parent + ' ' + selector : selector, atRule));
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
          var def = '$property:$value';
          if (atRule != null) {
            if (!media.exists(atRule)) {
              media.set(atRule, []);
            }
            media.get(atRule).push(def);
          } else {
            body.push(def);
          }
        case None:
          Context.error('Only static values are allowed in raw css', expr.pos);
      }
    case CssRaw(css):
      Context.error('Raw strings are not allowed when creating raw css', expr.pos);
  }
  
  for (expr in exprs) generateRawCssExpr(expr);
  
  if (body.length > 0) {
    out.push('$parent {${body.join(';')}}');
  }

  for (atRule => body in media) {
    out.push('@$atRule { $parent {${body.join(';')}} }');
  }

  return out.join('\n');
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
          
          switch f.expr.expr {
            case EConst(CIdent('true')):
              selector.push('(${name})');
            case EConst(CIdent('false')):
              selector.push('not (${name})');
            default:
              var value = switch prepareValue(f.expr, true).expr {
                case EConst(CString(s, _)): s;
                default: throw 'assert';
              }
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

function prepareValue(expr:Expr, ?onlyStaticValues = false):Expr {
  return switch expr.expr {
    case EArrayDecl(values):
      return {
        expr: EArrayDecl(values.map(value -> prepareValue(value, onlyStaticValues))),
        pos: expr.pos
      };
    case EBinop(op, e1, e2):
      var prepared = { 
        expr: EBinop(op, prepareValue(e1, onlyStaticValues), prepareValue(e2, onlyStaticValues)), 
        pos: expr.pos 
      };
      return switch extractStaticValue(prepared) {
        case Some(v): macro $v{v};
        case None if (!onlyStaticValues): prepared;
        case None:
          Context.error('Only static values are allowed here', expr.pos);
      }
    case ECall(e, params):
      switch e.expr {
        case EConst(CIdent(name)): switch name {
          case 'list':
            var exprs = params.map(value -> prepareValue(value, onlyStaticValues));
            switch mergeList(exprs, ',') {
              case Some(v):
                macro $v{v};
              case None if (!onlyStaticValues): 
                macro [ $a{exprs} ].join(',');
              case None:
                Context.error('Only static values are allowed here', expr.pos);
            }
          default:
            var exprs = params.map(value -> prepareValue(value, onlyStaticValues));

            // @todo: This is kinda hacky
            if (name == 'theme') {
              name = 'var';
              if (exprs.length > 2) {
                Context.error('Too many params', e.pos);
              }
              if (exprs.length < 1) {
                Context.error('Requires param', e.pos);
              }
              switch exprs[0].expr {
                case EConst(CString(s, _)) | EConst(CIdent(s)):
                  exprs[0].expr = EConst(CString('--' + s));
                case EField(_, _):
                  exprs[0].expr = EConst(CString(exprToVarName(exprs[0])));
                default:
                  Context.error('expected a string', exprs[0].pos);
              }
            } else {
              // @todo: Is there a better way to do this? Right now
              // we don't handle cammelCase like we do with other properties.
              // I wish CSS was consistant about this :P
              name = name.replace('_', '-');
            }

            switch mergeList(exprs, ',') {
              case Some(v): 
                // name = generateCssPropertyName(name);
                var str = name + '(' + v + ')';
                return macro $v{str};
              case None if (!onlyStaticValues):
                // name = generateCssPropertyName(name);
                macro $v{name} + '(' + [ $a{exprs} ].join(',') + ')';
              case None:
                Context.error('Only static values are allowed here', expr.pos);
            }
        }
        default:
          if (onlyStaticValues) return switch extractStaticValue(expr) {
            case Some(v): macro $v{v};
            case None:
              Context.error('Only static values are allowed here', expr.pos);
          }
          expr;
      }
    default: 
      if (onlyStaticValues) return switch extractStaticValue(expr) {
        case Some(v): macro $v{v};
        case None:
          Context.error('Only static values are allowed here', expr.pos);
      }
      expr;
  }
}
