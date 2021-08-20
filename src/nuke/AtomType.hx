package nuke;

import nuke.Atom;

enum AtomType {
  AtomChild(selector:String, atom:Atom);
  AtomAtRule(atRule:String, atom:Atom);
  AtomStatic(className:String, css:String);
  AtomDynamic(prop:String, value:String);
  AtomPrerendered(className:String);
}
