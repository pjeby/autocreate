{expect, should} = chai = require 'chai'
should = should()
chai.use require 'sinon-chai'

{spy} = sinon = require 'sinon'

same = sinon.match.same

spy.named = (name, args...) ->
    s = if this is spy then spy(args...) else this
    s.displayName = name
    return s

auto = require './'

util = require 'util'

items = (val) -> Object.keys(val).map (k) -> [k, val[k]]

withSpy = (ob, name, fn) ->
    s = spy.named name, ob, name
    try fn(s) finally s.restore()

checkTE = (fn, msg) -> fn.should.throw TypeError, msg

















describe "auto(constructor)", ->

    describe "statically", ->

        it "has the same .name", ->
            expect(auto(cls = class Baz).name).to.equal cls.name

        it "has the same .prototype", ->
            expect(auto(class Foo).prototype).to.equal Foo.prototype
            
        it "has the same .__proto__", ->
            class X then @foo: 42
            class Y then @__proto__: X
            expect(auto(Y).__proto__).to.equal X
            expect(auto(Y).foo).to.equal 42
            
        it "is its own .prototype.constructor", ->
            a = auto(class X)
            expect(a::constructor).to.equal a

        it "has the same static properties", ->           
            expect(auto(class Q then @foo: 22).foo).to.equal 22

        it "has the same .__super__, or lack thereof", ->            
            class Y extends class X
            expect(auto(Y).__super__).to.equal X::
            expect(auto(X).__super__).to.equal undefined

        it "has identical descriptors (if platform-supported)", ->
            return @skip() unless get = Object.getOwnPropertyDescriptor
            class Q then Object.defineProperty(@, 'foo', get: -> 42)
            expect(get(auto(Q),'foo')).to.eql get(Q, 'foo')

        it "has the same symbol-props (if platform-supported)", ->
            return @skip() unless get = Object.getOwnPropertyDescriptor
            return @skip() unless Symbol?.iterator and Object.getOwnPropertySymbols
            class Q then @[Symbol.iterator] = ->
            expect(get(auto(Q),Symbol.iterator)).to.eql get(Q, Symbol.iterator)
                


    describe "when called", ->

        describe "with new", ->

            describe "invokes the wrapped constructor", ->
                it "with all arguments"
                it "with `this` as an instanceof wrapped"
                it "that is also an instanceof wrapper"
                it "returns the contructor's return value" 

        describe "without new", ->

            describe "invokes prototype.__class_call__()", ->
                it "with all arguments"
                it "and the prototype as this"
                it "returning its return value"

            describe "falls back to creating an instance", ->
                it "that it passes to the constructor"
                it "along with all arguments"
                it "and returning that instance"
                it "unless the constructor returns an object or function"



















