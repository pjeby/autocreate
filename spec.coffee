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



    describe "when called", (my) ->       

        beforeEach -> @setup = (check = ->) ->
            my = this
            @invoked = invoked = spy.named 'constructor', check

            class @cls
                my.original = @
                cls = auto @
                constructor: -> return my.invoked.apply(this, arguments)

        describe "with new", ->

            describe "invokes the wrapped constructor", ->

                it "with all arguments", ->
                    @setup()
                    new @cls(1,2,3)
                    @invoked.should.have.been.calledWithExactly(1,2,3)

                it "with `this` as an instanceof wrapped", ->
                    my = this
                    @setup -> expect(this).to.be.instanceOf(my.cls)
                    new @cls()
                    @invoked.should.have.been.calledOnce

                it "that is also an instanceof wrapper", ->
                    my = this
                    @setup -> expect(this).to.be.instanceOf(my.original)                    
                    new @cls()
                    @invoked.should.have.been.calledOnce

                it "returns the contructor's return value", ->
                    anObj = {}
                    @setup -> anObj
                    expect(new @cls).to.equal anObj





        describe "without new", ->

            describe "invokes prototype.__class_call__()", ->

                beforeEach ->
                    @setup()
                    @cls::__class_call__ = @cc = spy.named 'cc'
                    
                it "with all arguments", ->
                    @cls(99, 42)
                    @invoked.should.not.have.been.called
                    @cc.should.have.been.calledOnce
                    @cc.should.have.been.calledWithExactly(99, 42)

                it "and the prototype as this", ->
                    @cls(99, 42)
                    @cc.should.have.been.calledOnce
                    @cc.should.have.been.calledOn(@cls::)
                    
                it "returning its return value", ->
                    @cls::__class_call__ = @cc = spy.named 'cc', -> 42
                    expect(@cls()).to.equal 42
                    @cc.should.have.been.calledOnce
                    @invoked.should.not.have.been.called

            describe "falls back to creating an instance", ->

                it "that it passes to the constructor", ->
                    my = this
                    @setup ->
                        expect(this).to.be.instanceOf(my.cls)
                        expect(this).to.be.instanceOf(my.original)
                    @cls()
                    @invoked.should.have.been.calledOnce

                it "along with all arguments", ->
                    @setup()
                    @cls(5,6)
                    @invoked.should.have.been.calledOnce
                    @invoked.should.have.been.calledWithExactly(5, 6)

                it "and returning that instance", ->
                    inst = null
                    for anObj in [null, undefined, 42, "blah"]
                        @setup -> inst = this; return anObj
                        expect(@cls()).to.equal(inst, anObj)
                        @invoked.should.have.been.calledOnce

                it "unless the constructor returns an object or function", ->
                    for anObj in [{}, ->]
                        @setup -> anObj
                        expect(@cls()).to.equal anObj
                        @invoked.should.have.been.calledOnce





























