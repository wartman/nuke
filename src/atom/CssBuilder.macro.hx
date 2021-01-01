package atom;

import haxe.macro.Context;
import haxe.macro.Expr;
import atom.CssParser;

using StringTools;

class CssBuilder {
  public static function generateAtoms(e:Expr) {
    var css = CssParser.parse(e);
    var exprs:Array<Expr> = [];
    
    function generate(cssExprs:Array<CssExpr>, ?parent:String, ?atRule:String) {
      for (c in cssExprs) switch c.expr {
        case CssChildren(children):
          generate(children, parent, atRule);
        case CssWrapper(wrapper, children) if (wrapper.contains('&')):
          if (parent == null) {
            Context.error('Rules with "&" require a parent', c.pos);
          }
          generate(children, wrapper.replace('&', parent), atRule);
        case CssWrapper(wrapper, children) if (wrapper.startsWith(':')):
          generate(children, parent != null ? parent + wrapper : wrapper, atRule);
        case CssWrapper(wrapper, children):
          // todo: handle special cases like @font-face and @keyframes
          if (atRule != null) {
            Context.error('At-rules cannot be nested', c.pos);
          }
          generate(children, parent, wrapper);
        case CssRule(selector, children):
          generate(children, parent != null ? parent + ' ' + selector : selector );
        case CssAtom(expr) if (parent != null && atRule != null):
          exprs.push(macro atom.Css.createChildAtom(SelAtRule($v{atRule}, $v{parent}), ${expr}));
        case CssAtom(expr) if (parent != null):
          exprs.push(macro atom.Css.createChildAtom(SelChild($v{parent}), ${expr}));
        case CssAtom(expr) if (atRule != null):
          exprs.push(macro atom.Css.createChildAtom(SelAtRule($v{atRule}), ${expr}));
        case CssAtom(expr):
          exprs.push(macro atom.Css.createAtom(${expr}));
      }
    }

    generate(css);

    return macro @:pos(e.pos) ([ $a{exprs} ]:atom.ClassName);
  }

  public static function generateString(selector:Null<String>, e:Expr) {
    var results = CssParser.parseStatic(e);
    var decls:Array<String> = [];

    // Because we're enfocing static values, we can be sure that
    // only string expressions are returned.
    function getString(e:Expr) {
      return switch e.expr {
        case EConst(CString(s, _)): s;
        default: throw 'assert'; 
      }
    }

    function addRule(selector:String, exprs:Array<Expr>) {
      if (exprs.length > 0) {
        decls.push('${selector} {${exprs.map(getString).join('')}}');
      } 
    }

    function addAtRule(rule:String, selector:String, exprs:Array<Expr>) {
      if (exprs.length > 0) {
        decls.push('${rule} { ${selector} {${exprs.map(getString).join('')}} }');
      } 
    }

    function generate(cssExprs:Array<CssExpr>, selector:String) {
      var exprs:Array<Expr> = [];
      for (c in cssExprs) switch c.expr {
        case CssChildren(children):
          exprs = exprs.concat(generate(children, selector));
        case CssRule(childSelector, children):
          var sel = selector != null ? selector + ' ' + childSelector : childSelector;
          addRule(sel, generate(children, sel));
        case CssWrapper(wrapper, children) if (wrapper.contains('&')):
          if (selector == null) {
            Context.error('Rules with "&" require a parent', c.pos);
          }
          var sel = wrapper.replace('&', selector);
          addRule(sel, generate(children, sel));
        case CssWrapper(wrapper, children) if (wrapper.startsWith(':')):
          if (selector == null) {
            Context.error('Psuedo classes require a parent', c.pos);
          }
          var sel = selector + wrapper;
          addRule(sel, generate(children, sel));
        case CssWrapper(wrapper, children):
          // todo: handle special cases like @font-face and @keyframes
          addAtRule(wrapper, selector, generate(children, selector));
        case CssAtom(expr):
          exprs.push(expr);
      } 
      return exprs;
    }

    addRule(selector, generate(results, selector));

    return macro @:pos(e.pos) $v{decls.join('')}; 
  }

  public static function generateRule(name:String, css:Expr, pos:Position) {
    var clsName = 'Rule${name}';
    Context.defineType({
      name: clsName,
      pack: [ 'atom', 'rules' ],
      kind: TDClass(null, null, false, true),
      meta: [],
      fields: (macro class {
        @:keep public static final __RULE = Engine.getInstance().add($v{name}, ${css});
        public inline static final __NAME = new atom.ClassName($v{name});
      }).fields,
      pos: pos
    });
    return macro atom.rules.$clsName.__NAME;
  }
}
