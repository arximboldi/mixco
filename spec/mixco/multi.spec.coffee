# spec.mixco.multi
# ================
#
# Tests for multiple inheritance support.
#
# Most test heterarchies are taken from the [original C3
# paper](http://192.220.96.201/dylan/linearization-oopsla96.html)

describe 'mixco.multi', ->

    {multi, mro, hierarchy, inherited, isinstance, issubclass} =
        require '../../mixco/multi'

    # Hierarchies to test
    # -------------------
    #
    # Class heterarchy from the Dylan paper, figure 5. Make sure the
    # linearization respects the *Extended Precedence Graph*.

    class Pane
    class EditingMixin
    class EditablePane extends multi Pane, EditingMixin
    class ScrollingMixin
    class ScrollablePane extends multi Pane, ScrollingMixin
    class EditableScrollablePane extends multi ScrollablePane, EditablePane

    # Class heterarchy from the Dylan paper, figure 4. Example of
    # compatibility with CLOS.

    class ChoiceWidget
    class PopupMixin
    class Menu extends ChoiceWidget
    class NewPopupMenu extends multi Menu, PopupMixin, ChoiceWidget

    # Class heterarchy from the Dylan paper, figure 2.  Make sure
    # linearization is monotonic.

    class Boat
    class DayBoat extends Boat
    class WheelBoat extends Boat
    class EngineLess extends DayBoat
    class SmallMultiHull extends DayBoat
    class PedalWheelBoat extends multi EngineLess, WheelBoat
    class SmallCatamaran extends SmallMultiHull
    class Pedalo extends multi PedalWheelBoat, SmallCatamaran

    # Hierarchy of classes with methods and constructors that use
    # super.

    class A
        constructor: ->
            @a = 'a'
        method: -> "A"

    class B extends A
        constructor: ->
            super
            @b = 'b'
        method: -> "B>#{super}"

    class C extends A
        constructor: ->
            super
            @c = 'c'
        method: -> "C>#{super}"

    class D extends multi B, C
        constructor: ->
            super
            @d = 'd'
        method: -> "D>#{super}"

    class E extends A
        constructor: ->
            super
            @e = 'e'
        method: -> "E>#{super}"

    class F extends multi C, E
        constructor: ->
            super
            @f = 'f'
        method: -> "F>#{super}"

    class G extends multi D, F
        constructor: ->
            super
            @g = 'g'
        method: -> "G>#{super}"

    # Hierarchy of classes where classes that only inherit from
    # `object` magically get a superclass in a multiple inheritance
    # context.

    class Base1
        constructor: ->
            @base1 = 'base1'

    class Base2
        constructor: ->
            @base2 = 'base2'

    class Deriv extends multi Base1, Base2
        constructor: ->
            super
            @deriv = 'deriv'

    # Tests
    # -----

    describe 'mro', ->

        it 'generates empty linearization for arbitrary object', ->
            expect(mro {}).toEqual []

        it 'generates empty linearization for null object', ->
            expect(mro undefined).toEqual []
            expect(mro null).toEqual []

        it 'generates a monotonic linearization', ->
            expect(mro Pedalo).toEqual [
                Pedalo, PedalWheelBoat, EngineLess, SmallCatamaran,
                SmallMultiHull, DayBoat, WheelBoat, Boat, Object]

        it 'respects local precedence', ->
            expect(mro NewPopupMenu).toEqual [
                NewPopupMenu, Menu, PopupMixin, ChoiceWidget, Object]

        it 'respects the extended precedence graph', ->
            expect(mro EditableScrollablePane).toEqual [
                EditableScrollablePane, ScrollablePane, EditablePane,
                Pane, ScrollingMixin, EditingMixin, Object ]

    describe 'multi', ->

        it 'calls super properly in multi case', ->
            obj = new D
            expect(mro D).toEqual [D, B, C, A, Object]
            expect(obj.method()).toBe "D>B>C>A"

        it 'calls super properly in recursive multi case', ->
            obj = new G
            expect(mro G).toEqual [G, D, B, F, C, E, A, Object]
            expect(obj.method()).toBe "G>D>B>F>C>E>A"

        it 'gets constructed properly', ->
            obj = new D
            expect(obj.d).toBe 'd'
            expect(obj.c).toBe 'c'
            expect(obj.b).toBe 'b'
            expect(obj.a).toBe 'a'

        it 'can generates the original hierarchy when possible', ->
            expect(hierarchy D).not.toEqual mro D
            expect(hierarchy inherited D).not.toEqual mro(D)[1..]
            expect(hierarchy inherited inherited D).toEqual mro(D)[2..]

        it 'it memoizes generated superclasses', ->
            expect(inherited D).toBe multi B, C

        it 'throws error on inconsistent hierarchy', ->
            expect(-> multi D, C, B)
                .toThrow new Error "Inconsistent multiple inheritance"

        it 'makes sure the next constructor after a root class', ->
            obj = new Deriv
            expect(obj.base1).toBe 'base1'
            expect(obj.base2).toBe 'base2'
            expect(obj.deriv).toBe 'deriv'

    describe 'isinstance', ->

        it 'checks the classes of an object even with multiple inheritance', ->
            expect(isinstance new D, D).toBe true
            expect(isinstance new D, B).toBe true
            expect(isinstance new D, C).toBe true
            expect(isinstance new D, A).toBe true
            expect(isinstance new D, Object).toBe true
            expect(isinstance new A, Object).toBe true
            expect(isinstance new Object, A).toBe false
            expect(isinstance new Pedalo, D).toBe false
            expect(isinstance new Pedalo, A).toBe false
            expect(isinstance new Pedalo, SmallCatamaran).toBe true

    describe 'issubclass', ->

        it 'checks the relationships of classes even with multiple inheritance', ->
            expect(issubclass D, D).toBe true
            expect(issubclass D, B).toBe true
            expect(issubclass D, C).toBe true
            expect(issubclass D, A).toBe true
            expect(issubclass D, Object).toBe true
            expect(issubclass A, Object).toBe true
            expect(issubclass Object, A).toBe false
            expect(issubclass Pedalo, D).toBe false
            expect(issubclass Pedalo, A).toBe false
            expect(issubclass Pedalo, SmallCatamaran).toBe true

# License
# -------
#
# >  Copyright (C) 2013 Juan Pedro Bolívar Puente
# >
# >  This program is free software: you can redistribute it and/or
# >  modify it under the terms of the GNU General Public License as
# >  published by the Free Software Foundation, either version 3 of the
# >  License, or (at your option) any later version.
# >
# >  This program is distributed in the hope that it will be useful,
# >  but WITHOUT ANY WARRANTY; without even the implied warranty of
# >  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# >  GNU General Public License for more details.
# >
# >  You should have received a copy of the GNU General Public License
# >  along with this program.  If not, see <http://www.gnu.org/licenses/>.
