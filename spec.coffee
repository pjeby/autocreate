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
        it "has the same .name"
        it "has the same .prototype"
        it "has the same .__proto__"
        it "is its own .prototype.constructor"
        it "has the same .__super__, or lack thereof"
        it "has the same static properties"
        it "has identical descriptors (if platform-supported)"
        it "has the same symbol-props (if platform-supported)"

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







