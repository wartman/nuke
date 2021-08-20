package nuke;

import nuke.AtomType;

using Lambda;
using nuke.internal.Hash;
using nuke.internal.Prefix;

abstract Atom(AtomType) from AtomType {
  public inline static function createPrerenderedAtom(className:String) {
    return new Atom(AtomPrerendered(className));
  }

  public inline static function createAtom(property:String, value:String) {
    return new Atom(AtomDynamic(property, value));
  }

  public inline static function createStaticAtom(className:String, css:String) {
    return new Atom(AtomStatic(className, css));
  }

  public inline static function createWrappedAtom(selector, atom) {
    return new Atom(AtomChild(selector, atom));
  }

  public inline static function createAtRuleAtom(atRule, atom) {
    return new Atom(AtomAtRule(atRule, atom));
  }

  public inline function new(atom) {
    this = atom;
    switch this {
      case AtomPrerendered(_):
        // noop
      default:
        Engine.getInstance().add(this);
    }
  }

  public function shouldRegister() {
    return switch this {
      case AtomPrerendered(_): false;
      default: true;
    }
  }

  public function getHash():String {
    return switch this {
      case AtomChild(selector, atom) | AtomAtRule(selector, atom): 
        atom.getHash() + '-' + selector.hash();
      case AtomStatic(className, _): 
        className;
      case AtomDynamic(_, _): 
        toCss().hash().withPrefix();
      case AtomPrerendered(hash): 
        hash;
    }
  }

  @:to
  public function getClassName():ClassName {
    return getHash();
  }

  public function toCss():String {
    return switch this {
      case AtomChild(_, atom) | AtomAtRule(_, atom): atom.toCss();
      case AtomStatic(_, css): css;
      case AtomDynamic(prop, value): '$prop:$value';
      case AtomPrerendered(_): '';
    }
  }

  public function render():String {
    return switch this {
      case AtomChild(selector, atom):
        '.' + getHash() + selector + ' {${atom.toCss()}}';
      case AtomAtRule(atRule, atom):
        '@$atRule { ${atom.render()} }';
      case AtomStatic(className, css):
        '.$className {$css}';
      case AtomDynamic(_, _):
        '.${getHash()} {${toCss()}}';
      case AtomPrerendered(_): 
        '';
    }
  }
}