spec.mixco.value
================

Tests for the `mixco.value` module.

Module
------

    {Value, Reduce, Const, transform} = require('../../mixco/value')

Tests
-----

Tests for the **Value** base class.

    describe 'Value', ->

        it "is initialized to given value", ->
            v = new Value 5
            expect(v.value).toBe 5
            v = new Value "hello"
            expect(v.value).toBe "hello"

        it "notifies when value changes", ->
            callback = do createSpy
            v = new Value
            v.on 'value', callback
            do expect(callback).not.toHaveBeenCalled
            v.value = 5
            expect(callback).toHaveBeenCalledWith 5

        it "returns newly set value", ->
            v = new Value
            v.value = 5
            expect(v.value).toBe 5

Tests for the **Reduce** class.

    describe 'Reduce', ->

        v = null
        r = null

        beforeEach ->
            v = [new Value(1), new Value(2), new Value(3)]
            r = new Reduce ((a, b) -> a + b), v...

        it "reduces all given values with binary operation", ->
            expect(r.value).toBe 6

        it "updates when any of the values changes", ->
            v[1].value = 0
            expect(r.value).toBe 4
            v[0].value = 5
            expect(r.value).toBe 8

Tests for **transform**

    describe 'transform', ->

        it "applies a nullary operation", ->
            r = transform ((a) -> a*4), new Const 2
            expect(r.value).toBe 8
