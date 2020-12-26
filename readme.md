Atom
====

Atomic CSS for Haxe.

About
-----

This is an attempt to create something like [Otin](https://github.com/kripod/otion) for Haxe. Still way too early to be useful yet.

Usage
-----

Atom gives you two ways of creating CSS in haxe: `atoms` and `rules`. Rules are _static_, and cannot accept non-static values (that is, only Constants (like strings or ints) or `static final` properties are allowed). `atoms` will accept any value.

More importantly, every css property in an `atom` will create their own CSS rule, which will only be injected once and will be reused if the `atom` is encountered again. For example, these are the same:

```haxe
var height = 120;
var foo = Css.atoms({ width: Px(150), height: Px(height) });
var bar = Css.atoms({ width: Px(150), height: Px(height) });

foo == bar; // true
```

In contrast, `rule` will generate a single Css rule that will be used only once even if its properties are the same.

```haxe
var foo = Css.rule({ width: Px(150), height: Px(120) });
var bar = Css.rule({ width: Px(150), height: Px(120) });

foo == bar; // false
```

There's a lot more going on here, but generally you should use `atoms` by default and only use `rules` when it makes sense.

> This is a terrible way to explain what I'm doing, but check Otion's readme for a better idea of what the concepts behind this are for now.
