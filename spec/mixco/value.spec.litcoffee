spec.mixco.value
================

Tests for the `mixco.value` module.

Module
------

    {Value, Reduce, Const, transform} = require '../../mixco/value'

Tests
-----

Tests for the **Value** base class.

    describe 'Value', ->

        it "is initialized to given value", ->
            v = new Value initial: 5
            expect(v.value).toBe 5
            v = new Value initial: "hello"
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
            v = [
                new Value initial: 1
                new Value initial: 2
                new Value initial: 3
            ]
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

License
-------

>  Copyright (C) 2013 Juan Pedro Bolívar Puente
>
>  This program is free software: you can redistribute it and/or
>  modify it under the terms of the GNU General Public License as
>  published by the Free Software Foundation, either version 3 of the
>  License, or (at your option) any later version.
>
>  This program is distributed in the hope that it will be useful,
>  but WITHOUT ANY WARRANTY; without even the implied warranty of
>  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
>  GNU General Public License for more details.
>
>  You should have received a copy of the GNU General Public License
>  along with this program.  If not, see <http://www.gnu.org/licenses/>.
