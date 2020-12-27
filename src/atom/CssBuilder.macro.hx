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
    var decls:Array<String> = [];

    function addDecl(selector:String, exprs:Array<Expr>) {
      if (exprs.length > 0) {
        var exprStr = exprs.map(e -> switch e.expr {
          // Because we're enfocing static values, we can be sure that
          // only string expressions are returned.
          case EConst(CString(s, _)): s;
          default: throw 'assert'; 
        });
        decls.push('${selector} {${exprStr.join('')}}');
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

    return macro @:pos(e.pos) $v{decls.join('')}; 
  }

  public static function generateRule(name:String, css:Expr, pos:Position) {
    var clsName = 'Rule${name}';
    Context.defineType({
      name: clsName,
      pack: [ 'atom', 'rules' ],
      kind: TDAbstract(macro:atom.ClassName, [], [macro:atom.ClassName]),
      meta: [],
      fields: (macro class {
        @:keep public static final __RULE__ = Engine.getInstance().add($v{name}, ${css});
        public inline function new() this = new atom.ClassName($v{name});
      }).fields,
      pos: pos
    });
    return macro new atom.rules.$clsName();
  }

  static function parse(e:Expr, staticValuesOnly:Bool = false):Array<CssResult> {
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

  static function parseRule(selector:String, props:Array<ObjectField>, staticValuesOnly:Bool):CssResult {
    var results:Array<CssResult> = [];

    for (prop in props) switch prop.expr.expr {
      case EObjectDecl(fields):
        results.push(parseRule(prop.field, fields, staticValuesOnly));
      default:
        results.push(CssRule(selector, [ parseProperty(prop.field, prop.expr, staticValuesOnly) ]));
    }

    return if (results.length == 1) results[0] else CssChildren(results);
  }

  static function parseProperty(name:String, value:Expr, staticValuesOnly:Bool):CssResult {
    var key = prepareKey(name);
    return switch value.expr { 
      case EObjectDecl(fields):
        parseRule(name, fields, staticValuesOnly);
      default: 
        if (staticValuesOnly) {
          return CssAtom(macro @:pos(value.pos) $v{key + ':' + extractStaticValue(value) + ';'});
        }
        CssAtom(macro @:pos(value.pos) $v{key} + ':' + (${value}:atom.CssValue) + ';');
    }
  }

  // @todo: this could use A LOT OF cleanup.
  static function extractStaticValue(value:Expr):String {
    if (Context.unify(Context.typeof(value), Context.getType('atom.CssUnit'))) {
      switch value.expr {
        case EConst(CIdent(name)):
          var local = Context.getLocalClass().get();
          var f = local.findField(name, true);
          if (f != null && f.isFinal) {
            return extractCssUnitValue(Context.getTypedExpr(f.expr()));
          } else {
            Context.error('A static value is requried', value.pos);
          }
        case EField(a, b):
          return extractCssUnitValue(Context.getTypedExpr(getField(a, b, value.pos).expr()));
        default: return extractCssUnitValue(value);
      }
    }

    return switch value.expr {
      case EConst(CIdent(name)):
        var local = Context.getLocalClass().get();
        var f = local.findField(name, true);
        if (f != null && f.isFinal) {
          return switch f.expr().expr {
            case TConst(TString(s)): s;
            case TConst(TInt(s)): Std.string(s);
            case TConst(TFloat(s)): Std.string(s);
            default: Context.error('A static value is requried', value.pos);
          }
        }
        Context.error('A static value is requried', value.pos);
        null;
      case EConst(CString(s, _)): s;
      case EConst(CInt(s)): Std.string(s);
      case EConst(CFloat(s)): Std.string(s);
      case EField(a, b): switch getField(a, b, value.pos).expr().expr {
        case TConst(TString(s)): s;
        case TConst(TInt(s)): Std.string(s);
        case TConst(TFloat(s)): Std.string(s);
        default: Context.error('A static value is requried', value.pos);
      }
      default: Context.error('A static value is requried', value.pos);
    }
  }

  static function getTypePathFromExpr(e:Expr, pos):String {
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

  static function getField(a:Expr, name:String, pos) {
    var typeName = getTypePathFromExpr(a, pos);
    if (typeName.indexOf('.') < 0) {
      typeName = getTypePath(typeName, Context.getLocalImports());
    }
    var type = try {
      Context.getType(typeName).getClass();
    } catch (e:String) {
      Context.error('The type ${typeName} was not found', pos);
    }
    var f = type.findField(name, true);
    if (f == null) {
      Context.error('The field ${typeName}.${name} does not exist', pos);
    }
    if (!f.isFinal) {
      Context.error('Fields must be static and final', pos);
    }
    return f;
  }
  
  static function extractCssUnitValue(value:Expr) return switch value.expr {
    case ECall(unit, params) if (params.length > 0):
      var str = extractStaticValue(params[0]);
      var suffix = switch unit.expr {
        case EConst(CIdent(s)): switch s {
          case 'Pct': '%';
          case 'Sec': 's';
          case 'Num': '';
          default: s.toLowerCase();
        }
        case EField(_): switch getTypePathFromExpr(unit, value.pos).split('.').pop() {
          case 'Pct': '%';
          case 'Sec': 's';
          case 'Num': '';
          case s: s.toLowerCase();
        }
        default: throw 'assert';
      }
      str + suffix;
    case ECall(unit, _):
      switch unit.expr {
        case EConst(CIdent('Auto')): 'auto';
        case EConst(CIdent('None')): '0';
        case EField(_): switch getTypePathFromExpr(unit, value.pos).split('.').pop() {
          case 'Auto': 'auto';
          case 'None': '0';
          default: throw 'assert';
        }
        default: throw 'assert';
      }
    default:
      ''; 
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
