# autocreate

Sometimes, you need something to be both a class and a function.  Sometimes, you need a class to be callable without using `new`.  The `autocreate` module makes it as easy as typing `@auto` before your class declaration (in Babel or TypeScript), and almost that easy in CoffeeScript or Javascript.  (And there are probably ways to use it with other compile-to-Javascript languages, too!)

`autocreate` does not depend on any particular version of Javascript in its execution environment: if you're using a language that works on old versions of IE, then `autocreate` will work there too.  If you're targeting an ES5 or ES6 environment, no problem: `autocreate` will detect the relevant features (descriptors, symbols, `__proto__`, etc.) and progressively enhance itself to support them.

Last, but not least, `autocreate` also lets you create classes that take a different code path when invoked without `new`, for those cases where you need to e.g. return an object from a cache, return an object that was passed in, etc.


### Contents

<!-- toc -->

<!-- toc stop -->

## Usage Synopsis

#### Create a class that doesn't need `new`, in:

**TypeScript or Babel w/ES7 Features**
```javascript
auto = require('autocreate');

@auto class MyClass {
  constructor() {
    // No need to check for `this instanceof`;
    // just do whatever needs doing.
  }
}
```

**CoffeeScript**
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

**Javascript:**
```javascript
var auto = require('autocreate');

var MyClass = auto( function MyClass () {
  // No need to check for `this instanceof`;
  // just do whatever needs doing.
});
```

#### Create a class with alternate code path

**TypeScript or Babel w/ES7 Features**
```javascript
@auto class MyClass {
  constructor() {
    // This will run if `new MyClass()` is used
  }
  __class_call__() {
    // This will run if `MyClass()` is called
  }
}
```

**CoffeeScript**
```coffeescript
class MyClass
  MyClass = auto @

  constructor: ->
    # This will run if `new MyClass()` is used

  __class_call__: ->
    # This will run if `MyClass()` is called
```

**Javascript:**
```javascript
var auto = require('autocreate')

var MyClass = auto( function MyClass () {
  // This will run if `new MyClass()` is used
});

MyClass.prototype.__class_call__ = function () {
  // This will run if `MyClass()` is called
}
```


## Developer's Guide

