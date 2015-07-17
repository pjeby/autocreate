# autocreate

Sometimes, you need something to be both a class and a function.  Sometimes, you need a class to be callable without using `new`.  The `autocreate` module makes both as easy as typing `@auto` before your class declaration (in Babel/ES7 or TypeScript), and almost that easy in CoffeeScript or Javascript.  (And there are probably ways to use it with other compile-to-Javascript languages, too!)

```javascript
auto = require('autocreate');

@auto class MyClass {
  constructor() {
    // No need to check for `this instanceof`;
    // just do whatever needs doing.
  }
}
```

`autocreate` supports even the most exotic class features of these languages, including static methods and properties, automatically bound methods, etc. -- even non-enumerable property descriptors and getter/setters.

It does not, however, depend on any particular version of Javascript as its execution environment: if you're using a language and featureset that works on old versions of IE, then `autocreate` will work there too.  If you're targeting an ES5 or ES6 environment, no problem: `autocreate` will detect the relevant features (descriptors, symbols, `__proto__`, etc.) and progressively enhance itself to support them.

Last, but not least, `autocreate` includes a special hook method that you can define to customize what happens when the class is called without `new`.  That way, you can return an object from a cache, return an object that was passed in (like `Object(obj)` does), or generaly do things differently when invoked without `new`.


#### Contents

<!-- toc -->

<!-- toc stop -->

## Usage

#### Create a `new`-less class

##### In TypeScript (or Babel w/ES7 features enabled)

```javascript
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
  # You have to do this assignment inside the class body, with
  # the same name as the class, since CS lacks decorators
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
});
```

#### Create a class with separate "function" behavior

##### In TypeScript (or Babel w/ES7 features enabled)
```javascript
@auto class MyClass {
  constructor() {
    // This will run if `new MyClass()` is used
  }
  __class_call__() {
    // This will run if `MyClass()` is called
    // with `this === MyClass.prototype`
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
    # This will run if `MyClass()` is called
    # with `this === MyClass.prototype`
```

##### In Plain Javascript
```javascript
MyClass = auto(MyClass);

function MyClass () {
  // This will run if `new MyClass()` is used
});

MyClass.prototype.__class_call__ = function () {
  // This will run if `MyClass()` is called
  // with `this === MyClass.prototype`
}
```


## Implementation Details


### Constructor Wrapping

`autocreate` works by creating a new constructor function to wrap the old one.  It copies any static methods, properties, descriptors, `__proto__` etc., so that even Babel's most advanced class features will still work on the result.  It even shares the original constructor's `.prototype` and resets the `.constructor`, so that created objects will still be an `instanceof` both the wrapper and the wrapped constructor.

### In-Namespace Replacement

For this to work correctly in a given language, the wrapper *must* replace the wrapped constructor *in the same namespace* where it was defined.

For plain Javascript, this is simple: just set `MyClass = auto(MyClass);`, and you're done.  For other languages, it's a little more complex, because most compile-to-Javascript languages wrap the definition of a class constructor inside a closure.

For TypeScript and Babel (w/ES7 decorators enabled), the `@auto` decorator syntax handles this: it actually replaces the constructor inside the closure, in a way that would not always work if you just used `MyClass = auto(MyClass);`.  (Because generated methods inside the class-closure could refer to the wrong constructor.)

CoffeeScript, however, doesn't have a decorator syntax, which is why you have to do `MyClass = auto @` (or `MyClass = auto this`) *inside* the class body.  If you do it from outside the class body, all the code inside the class body will refer to the original constructor.  Also, it's important to note that the `MyClass` part of the statement *must* match CoffeeScript's *generated class name*.  That is:

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

Determining the correct way to do this in the language of your choice (other than Babel, TS, CS, etc.) is left as an exercise for the reader.  Take a look at the code your language generates for a class statement, or if it has an online interactive "playground" the way Babel, TS, and CS do, even better!

### Return Value Handling

`autocreate` respects the standard Javascript rules for constructor return values.  If your wrapped constructor returns and object or function, it will be returned in place of the newly-created instance -- regardless of whether the wrapper was called with `new` or not.

On the other hand, if you supply a `__class_call__` method, its return value will *always* be returned from the wrapper, regardless of type.  This allows the function to behave as a normal function, when called as one.

### Inheritance

If you create a subclass of an `@auto` class, you should make it `@auto` as well.  This is because it's impossible for a constructor to know whether it's being called directly, or via a subclass `super` call.  Thus, even though the base class can tell that it wasn't invoked with `new`, it *can't* tell *which* class it should create an instance of!

Also, you should be aware that since `__class_call__` is a normal instance method, it is automatically inherited by subclasses.  If you don't want the subclasses to respond to it, you can override the method in the subclasses, or you can write the method like this (Babel/ES7):

```javascript
@auto class BaseClass {
  __class_call__() {
    if (this !== BaseClass.prototype) {
      // Create and return a subclass instance
      return new this.constructor(...arguments)
    }
    // ... 
    // whatever `Base()` should do w/out `new`
  }
}

@auto class Subclass extends BaseClass {
  // ... etc.
}
```

