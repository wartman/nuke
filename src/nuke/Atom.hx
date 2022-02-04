package nuke;

import nuke.AtomType;

using Lambda;
using nuke.internal.Hash;
using nuke.internal.Prefix;

abstract Atom(AtomType) from AtomType {
  public inline static function createPrerenderedAtom(className:String) {
    return new Atom(AtomPrerendered(className));
  }

  public inline static function createAtom(property:String, value:Value) {
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
  }

  /**
    Inject the atom into the current engine.

    This *must* be called if you want the atom to work -- if you're
    using the `nuke.Css.atoms(...)` api this will be handled automatically,
    but be aware of it if you're manually creating Atoms.
  **/
  public inline function inject() {
    Engine.getInstance().add(this);
    return this;
  }

  public function getHash():String {
    return switch this {
      case AtomChild(selector, atom) | AtomAtRule(selector, atom): 
        atom.getHash() + '-' + selector.hash();
      case AtomStatic(hash, _): 
        hash;
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
      case AtomAtRule(_, atom) | AtomChild(_, atom): atom.toCss();
      case AtomStatic(_, css): css;
      case AtomDynamic(prop, value): '$prop:$value';
      case AtomPrerendered(_): '';
    }
  }

  public function render():String {
    return switch this {
      case AtomChild(selector, atom):
        '.' + getHash() + selector + ' {${atom.toCss()}}';
      case AtomAtRule(atRule, atom): switch atom.unwrap() {
        case AtomChild(selector, atom):
          '@$atRule { .${getHash()}${selector} {${atom.toCss()}} }';
        default:
          '@$atRule { .${getHash()} {${atom.toCss()}} }';
      }
      case AtomStatic(className, css):
        '.$className {$css}';
      case AtomDynamic(_, _):
        '.${getHash()} {${toCss()}}';
      case AtomPrerendered(_): 
        '';
    }
  }

  inline function unwrap():AtomType {
    return this;
  }
}
