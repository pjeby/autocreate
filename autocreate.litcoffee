# `new`-less classes for ES7/Babel, TypeScript, and CoffeeScript

## Wrapper Behavior

The sole purpose of this module is to create a wrapper around a class
constructor.  The wrapper should have the same name and properties as the
original class, and take care of detecting when `new` has or hasn't been
called.

    module.exports = auto = (cons) ->

        proto = cons.prototype

        cls = copyProps(cons, named(cons, ->

If we were called with `new`, then `this` will an instance of the current class,
and we can just apply the constructor.

            if this instanceof cls
                cons.apply(this, arguments)

If we weren't called with a valid instance, but the prototype has a
`__class_call__` method, we invoke that and return whatever it returns.

            else if cc = proto.__class_call__
                cc.apply(proto, arguments)

Otherwise, we fall back to creating an instance, then applying the constructor
to it, emulating Javascript's native behavior for constructor return values.

            else
                inst = create(proto)
                ret = cons.apply(inst, arguments)
                if Object(ret) is ret then ret else inst
            )
        )

Object creation is handled using an ES3 polyfill for single-argument
`Object.create()`.  We always use it, even when `Object.create()` is around,
because some engines run faster with objects made by `new`.

The polyfill works by setting its own `.prototype`, then calling `new` on
itself in such a way that the prototype is immediately cleared, preventing a
dangling reference.

    create = (proto) ->
        create.prototype = proto
        return new create() if proto


































## Wrapper Properties

To work as a replacement for the original class, the wrapper function must have
(to the extent possible) the same prototype (i.e. `__proto__`), properties,
etc. as the wrapped class.

If we're in an ES5+ environment, we can query and define property descriptors,
so we should copy them.  TypeScript and CoffeeScript don't use them, but
Babel depends on them.  (IE8 has `getOwnPropertyDescriptor()` and
`defineProperty()`, but not `getOwnPropertyNames()`, so we won't end up using
its broken DOM-only junk.)

    getDesc = Object.getOwnPropertyDescriptor
    defProp = Object.defineProperty

    copyProps = (src, dst) ->

        keys = []
        .concat(Object.getOwnPropertyNames?(src) ? [])
        .concat(Object.getOwnPropertySymbols?(src) ? [])

        if keys.length and getDesc? and defProp?
            for k in keys

Some built-in function properties (e.g. `length`) are neither writable nor
configurable, but will already exist on the destination.  We check for those
and skip them.  But if a non-configurable property is writable (e.g.
`prototype`), we can still try to assign to it first.

                d = getDesc(dst, k)
                if d?.configurable is false
                    dst[k] = src[k] if d.writable
                    continue

But if the property doesn't exist on the destination, or is configurable, we
can go ahead and redefine it.  For simplicity's sake, errors are ignored.

                try defProp(dst, k, getDesc(src, k))



In a non-ES5 environment, we fall back to copying enumerable own-property
values, and assigning the prototype.

        else
            for own k, v of src then dst[k] = v
            dst.prototype = src.prototype

Babel relies on `__proto__` assignment, so we try to do it, too.  But only if
the `__proto__` is *different*, and on a platform that doesn't support it, they
should both have a value of `undefined`.

        unless dst.__proto__ is src.__proto__
            try dst.__proto__ = src.__proto__

Last, but not least, we make the prototype's `constructor` point to the wrapper
so that instances' "class" is the wrapper, not the wrapped constructor.

        dst.prototype.constructor = dst
        dst






















## Wrapper Name (and `.length`)

For debugging purposes, the wrapper's name should be the same as the wrappee's
name.  As of ES6, function names are supposed to be writable or at least
configurable.  But if we're not in such an environment, it's necessary to
dynamically create a *second* wrapper function in order to give it the right
name.  (At which point, we might as well try to give it the same length.)

(Unfortunately, in a browser with a Content Security Policy, `new Function`
will fail, so we need to catch any error from that and just give up at that
point.)

    named = (src, dst) ->
        for prop in ['name', 'length']

            if dst[prop] isnt src[prop]
                try dst[prop] = src[prop]

            if dst[prop] isnt src[prop]
                try Object.defineProperty(dst, prop, value: src[prop])

        if dst.name isnt src.name or dst.length isnt src.length
            args =""
            args = "arg"+[1..src.length].join(', arg') if src.length

            try dst = new Function(
                '$$'+src.name, body = """\
                return function NAME(#{args}) {
                    return $$NAME.apply(this, arguments);
                }
                """.replace /NAME/g, src.name
            )(dst)

        return dst







