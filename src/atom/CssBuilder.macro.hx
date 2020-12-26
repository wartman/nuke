package atom;

import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;
using haxe.macro.Tools;

enum CssResult {
  CssRule(selector:String, children:Array<CssResult>);
  CssChildren(children:Array<CssResult>);
  CssWrapper(wrapper:String, children:Array<CssResult>);
  CssAtom(expr:Expr);
}

class CssBuilder {
  static final ucase:EReg = ~/[A-Z]/g;

  public static function generateAtoms(e:Expr) {
    var results = parse(e);
    var exprs:Array<Expr> = [];
    
    function generate(results:Array<CssResult>, ?parent:String) {
      for (result in results) switch result {
        case CssChildren(children):
          generate(children, parent);
        case CssWrapper(wrapper, children):
          // todo -- will be for at-rules and stuff.
        case CssRule(selector, children):
          generate(children, parent != null ? parent + ' ' + selector : selector );
        case CssAtom(expr) if (parent != null):
          exprs.push(macro atom.Css.createChildAtom($v{parent}, ${expr}));
        case CssAtom(expr):
          exprs.push(macro atom.Css.createAtom(${expr}));
      }
    }

    generate(results);

    return macro @:pos(e.pos) ([ $a{exprs} ]:atom.ClassName);
  }

  public static function generateString(selector:Null<String>, e:Expr) {
    var results = parse(e, true);
    var decls:Array<Expr> = [];

    function addDecl(selector:String, exprs:Array<Expr>) {
      if (exprs.length > 0) {
        decls.push(macro $v{selector} + ' {' + [ $a{exprs} ].join('') + '}');
      } 
    }

    function generate(results:Array<CssResult>, selector:String) {
      var exprs:Array<Expr> = [];
      for (result in results) switch result {
        case CssChildren(children):
          exprs = exprs.concat(generate(children, selector));
        case CssRule(childSelector, children):
          var sel = selector != null ? selector + ' ' + childSelector : childSelector;
          addDecl(sel, generate(children, sel));
        case CssWrapper(wrapper, children):
          // todo -- will be for at-rules and stuff.
        case CssAtom(expr):
          // @todo: Ensure that ONLY static values are allowed here.
          exprs.push(expr);
      } 
      return exprs;
    }

    addDecl(selector, generate(results, selector));

    return macro @:pos(e.pos) [ $a{decls} ].join('\n'); 
  }

  public static function parse(e:Expr, staticValuesOnly:Bool = false):Array<CssResult> {
    var results:Array<CssResult> = [];

    switch e.expr {
      case EObjectDecl(fields) if (fields.length >= 0):
        for (field in fields) results.push(parseProperty(field.field, field.expr, staticValuesOnly));
      case EConst(CString(_, _)):
        results.push(CssAtom(e));
      case EBlock(_) | EObjectDecl(_):
        macro null;
      default:
        Context.error('Should be an object', e.pos);
    }

    return results;
  }

  public static function parseRule(selector:String, props:Array<ObjectField>, staticValuesOnly:Bool):CssResult {
    var results:Array<CssResult> = [];

    for (prop in props) switch prop.expr.expr {
      case EObjectDecl(fields):
        results.push(parseRule(prop.field, fields, staticValuesOnly));
      default:
        results.push(CssRule(selector, [ parseProperty(prop.field, prop.expr, staticValuesOnly) ]));
    }

    return if (results.length == 1) results[0] else CssChildren(results);
  }

  public static function parseProperty(name:String, value:Expr, staticValuesOnly:Bool):CssResult {
    var key = prepareKey(name);
    return switch value.expr { 
      case EObjectDecl(fields):
        parseRule(name, fields, staticValuesOnly);
      default: 
        if (staticValuesOnly) ensureStaticValue(value);
        CssAtom(macro @:pos(value.pos) $v{key} + ':' + (${value}:atom.CssValue) + ';');
    }
  }

  static function ensureStaticValue(value:Expr) {
    // Special case: Allow `atom.CssUnit` to be used as long as its params
    // are static.
    if (Context.unify(Context.typeof(value), Context.getType('atom.CssUnit'))) {
      switch value.expr {
        case ECall(_, params) if (params.length > 0):
          ensureStaticValue(params[0]);
          return;
        default: return; 
      }
    }

    switch value.expr {
      case EConst(CIdent(name)):
        var local = Context.getLocalClass().get();
        var f = local.findField(name, true);
        if (f != null && f.isFinal) {
          return;
        }
        Context.error('A static value is requried', value.pos);
      case EConst(_): value;
      case EField(a, b): // todo: pull this out?
        function extract(e:Expr):String {
          return switch e.expr {
            case EField(a, b): 
              extract(a) + '.' + b;
            case EConst(CIdent(s)): 
              s;
            default:
              Context.error('Invalid expression', value.pos);
              null;
          }
        }
        var typeName = extract(a);
        if (typeName.indexOf('.') < 0) {
          typeName = getTypePath(typeName, Context.getLocalImports());
        }
        var type = try {
          Context.getType(typeName).getClass();
        } catch (e:String) {
          Context.error('The type ${typeName} was not found', value.pos);
        }
        var f = type.findField(b, true);
        if (f == null) {
          Context.error('The field ${typeName}.${b} does not exist', value.pos);
        }
        if (!f.isFinal) {
          Context.error('Fields must be static and final', value.pos);
        }
        switch f.expr().expr {
          case TConst(TString(s)): s;
          case TConst(TInt(s)): Std.string(s);
          default: Context.error('A static value is requried', value.pos);
        }
      default: Context.error('A static value is requried', value.pos);
    }
  }

  static function getTypePath(name:String, imports:Array<ImportExpr>):String {
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

  static function prepareKey(key:String) {
    return [ for (i in 0...key.length)
      if (ucase.match(key.charAt(i))) {
        if (i == 0)
          key.charAt(i).toLowerCase()
        else 
          '-' + key.charAt(i).toLowerCase();
      } else {
        key.charAt(i);
      } 
    ].join('');
  }
}
