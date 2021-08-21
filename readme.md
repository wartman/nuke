Nuke
====

Atomic CSS for Haxe.

About
-----

This is an attempt to create something like [Otin](https://github.com/kripod/otion) for Haxe. Still way too early to be useful yet.

It's main benefit is that it uses Haxe's macro system to automatically check if an atom is dynamic or static, and can extract all static atoms and place them in an external CSS file. Ideally, Nuke should be able to compile itself away and just leave some class names at runtime. 

Usage
-----

Nuke's API is simple, consisting of a few methods. Most of the complicated stuff happens behind the scenes.

To get stated, import Nuke with `using Nuke` at the top of the file. This will expose the `Css` Api, some special extension methods to convert Floats and Ints into CSS units, and `ClassName`.

```haxe
using Nuke;

function main() {
  var classOne:ClassName = Css.atoms({
    width: 20.px(),
    height: 20.px() + 20.px() // will be converted into `calc(20px + 20px)`
  });
}
```

> todo: more to come
