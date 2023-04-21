package nuke;

import nuke.Atom;

enum AtomType {
  AtomChild(selector:String, atom:Atom);
  AtomAtRule(atRule:String, atom:Atom);
  AtomRaw(hash:String, css:String);
  AtomStatic(className:String, css:String);
  AtomDynamic(prop:String, value:Value);
  AtomPrerendered(className:String);
}
