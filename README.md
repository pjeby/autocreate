# autocreate

Sometimes, you need something to be both a class and a function.  Sometimes, you need a class to be callable without using `new`.  The `autocreate` module makes both as easy as typing `@auto` before your class declaration (in Babel/ES7 or TypeScript), and *almost* that easy in CoffeeScript or plain Javascript.

<!--mockdown-setup: languages.js = 'babel'; languages.babel.options.stage=0; -->

```js
auto = require('autocreate');

@auto class MyClass {
  constructor() {
    // No need to check for `this instanceof`;
    // just do whatever needs doing.
  }
}
```

`autocreate` also includes a special hook method that you can define to customize what happens when the class is called without `new`.  That way, you can return an object from a cache, return an object that was passed in (like `Object(obj)` does), or generaly do things differently when invoked without `new`:

```js
@auto class dualUse {
  constructor() {
    // this is called if you use `new dualUse()`
  }
  __class_call__() {
    // this is called if you use `dualUse()`
  }
}
```

For more usage details, including code samples for all of the supported languages, see the "Usage" section, below.  (`autocreate` will also *probably* work with most other compile-to-Javascript languages; read the "Implementation Details" section for more info!)

`autocreate` supports even the most exotic class features of its supported languages, including static methods and properties, automatically bound methods, etc. -- even non-enumerable property descriptors and getter/setters.

It does not, however, depend on any particular version of Javascript as its execution environment: if you're using a language whose features work on old versions of IE, then `autocreate` will work there too!  If you're targeting an ES5 or ES6 environment, no problem: `autocreate` will detect the relevant features (descriptors, symbols, `__proto__`, etc.) and progressively enhance itself to support them.


#### Contents

<!-- toc -->

* [Usage](#usage)
    * [Create a `new`-less class](#create-a-new-less-class)
    * [Create a class with separate "function" behavior](#create-a-class-with-separate-function-behavior)
* [Implementation Details](#implementation-details)
  * [Constructor Wrapping](#constructor-wrapping)
  * [In-Namespace Replacement](#in-namespace-replacement)
  * [Return Value Handling](#return-value-handling)
  * [Inheritance](#inheritance)

<!-- toc stop -->

## Usage

#### Create a `new`-less class

##### In TypeScript (or Babel w/ES7 features enabled)

```js
auto = require('autocreate');

@auto class MyClass {
  constructor() {
    // No need to check for `this instanceof`;
    // just do whatever needs doing.
  }
}
```

##### In CoffeeScript
```coffeescript
auto = require 'autocreate'

class MyClass

  # Because CoffeeScript doesn't have decorators, you have to
  # assign to the class name *inside* the class body
  
  MyClass = auto @

  constructor: ->
    # no need to check `this instanceof`;
    # just do whatever needs doing
```

##### In Plain Javascript
```javascript
var auto = require('autocreate');

MyClass = auto(MyClass);

function MyClass () {
  // No need to check for `this instanceof`;
  // just do whatever needs doing.
};
```

#### Create a class with separate "function" behavior

##### In TypeScript (or Babel w/ES7 features enabled)
```js
@auto class MyClass {
  constructor() {
    // This will run if `new MyClass()` is used
  }
  __class_call__() {
    // This will run if `MyClass()` is called:
    // `this` will be `MyClass.prototype`
  }
}
```

##### In CoffeeScript
```coffeescript
class MyClass
  MyClass = auto @

  constructor: ->
    # This will run if `new MyClass()` is used

  __class_call__: ->
    # This will run if `MyClass()` is called:
    # `this` will be `MyClass.prototype`
```

##### In Plain Javascript
```javascript
MyClass = auto(MyClass);

function MyClass () {
  // This will run if `new MyClass()` is used
};

MyClass.prototype.__class_call__ = function () {
  // This will run if `MyClass()` is called:
  // `this` will be  `MyClass.prototype`
}
```


## Implementation Details


### Constructor Wrapping

`autocreate` works by creating a new constructor function to wrap the old one.  It copies any static methods, properties, descriptors, `__proto__` etc., so that even Babel's most advanced class features will still work on the result.  It even shares the original constructor's `.prototype` and resets the `.constructor`, so that created objects will still be an `instanceof` both the wrapper and the wrapped constructor.

### In-Namespace Replacement

For this to work correctly in a given language, the wrapper *must* replace the wrapped constructor *in the same namespace* where it was defined.

For plain Javascript, this is simple: just set `MyClass = auto(MyClass);`, and you're done.  For other languages, it's a little more complex, because most compile-to-Javascript languages wrap the definition of a class constructor inside a closure.

For TypeScript and Babel (w/ES7 decorators enabled), the `@auto` decorator syntax handles this: it actually replaces the constructor inside the closure, in a way that would not always work if you just used `MyClass = auto(MyClass);`.  (Because generated methods inside the class-closure could refer to the wrong constructor.)

CoffeeScript, however, doesn't have a decorator syntax, which is why you have to do `MyClass = auto @` (or `MyClass = auto this`) *inside* the class body.  If you do it from outside the class body, all the code *inside* the class body will refer to the original constructor!

Also, it's important to note that the `MyClass` part of the statement *must* match CoffeeScript's *generated class name*.  That is:

```coffeescript
class MyClass
  MyClass = auto @      # default

class foo.bar.Baz
  Baz = auto @          # last .name
  
class foo('Bar')['Baz'].Spam
  Spam = auto @         # even with expressions!

class
  _Class = auto @       # an anonymous class

class foo('Bar')['Baz']
  _Class = auto @       # no last .name
```

Determining the correct way to do this in the language of your choice (other than Babel, TypeScript, CoffeeScript, etc.) is left as an exercise for the reader.  (Take a look at the code your language generates for a class statement, or if it has an online interactive "playground" the way Babel, TS, and CS do, even better!)

### Return Value Handling

`autocreate` respects the standard Javascript rules for constructor return values.  If your wrapped constructor returns an object or function, it will be returned in place of the newly-created instance -- regardless of whether the wrapper was called with `new` or not.

On the other hand, if you supply a `__class_call__` method, its return value will *always* be returned from the wrapper, regardless of type.  This allows the class to behave like a normal function, when it's called as one.

(Of course, if you *want* your `__class_call__` to return an instance, you can create one via `new this.constructor(...)`, because `this` in a `__class_call__` is equal to the class's `.prototype`.)

### Inheritance

If you create a subclass of an `autocreate` class, you should make it `autocreate` as well.  This is because it's impossible for a constructor to know whether it's being called directly, or via a subclass `super` call.  Thus, even though the base class can tell it wasn't invoked with `new`, it can't tell *which* class it should create an instance of!

Also, you should be aware that since `__class_call__` is a normal instance method, it is automatically inherited by subclasses.  If you don't want the subclasses to respond to it, you can override the method in the subclasses, or you can write the method like this (Babel/ES7):

```js
@auto class BaseClass {
  __class_call__() {
    if (this !== BaseClass.prototype) {
      // Create and return an instance of the correct subclass
      return new this.constructor(...arguments)
    }
    // ... 
    // whatever `BaseClass()` should do w/out `new`
  }
}

@auto class Subclass extends BaseClass {
  // ... etc.
}
```

This will then return a `Subclass` instance when you call `Subclass()` without `new`, but fall through to whatever special handling you've set up when you call `BaseClass()` without `new`.

### Programmatic Subclass Creation

As a convenience feature for metaprogramming, `autocreate` exposes a `.subclass(name?, base, props?)` utility function for creating ES6-style subclasses of `base` with the given `name` and descriptors (`props`).  If `name` is null or omitted, the base class name is used.  Static properties are inherited via `__proto__`:

```js
let sub = auto.subclass('sub', BaseClass, {foo: {value: "bar"}});

BaseClass.somethingStatic = 42;

console.log(sub.name);
console.log(sub.somethingStatic);

console.log(sub().foo);
console.log(sub() instanceof sub);
console.log(sub() instanceof BaseClass);
```

>     sub
>     42
>     bar
>     true
>     true
 
Note that this function doesn't allow you to change the base class's constructor behavior, though you can of course define a new `__class_call__` in the subclass's properties.  It's mainly useful for creating ES5/ES6-style subclasses when your favorite language only does ES3-style inheritance.
