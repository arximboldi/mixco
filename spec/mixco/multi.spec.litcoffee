spec.mixco.multi
================

Tests for multiple inheritance support.

Most test heterarchies are taken from the [original C3
paper](http://192.220.96.201/dylan/linearization-oopsla96.html)

Module
------

    {multi, mro} = require '../../mixco/multi'

Tests
Hierarchies to test
-------------------

Class heterarchy from the Dylan paper, figure 5. Make sure the
linearization respects the *Extended Precedence Graph*.

    class Pane
    class EditingMixin
    class EditablePane extends multi Pane, EditingMixin
    class ScrollingMixin
    class ScrollablePane extends multi Pane, ScrollingMixin
    class EditableScrollablePane extends multi ScrollablePane, EditablePane

Class heterarchy from the Dylan paper, figure 4. Example of
compatibility with CLOS.

    class ChoiceWidget
    class PopupMixin
    class Menu extends ChoiceWidget
    class NewPopupMenu extends multi Menu, PopupMixin, ChoiceWidget

Class heterarchy from the Dylan paper, figure 2.  Make sure
linearization is monotonic.

    class Boat
    class DayBoat extends Boat
    class WheelBoat extends Boat
    class EngineLess extends DayBoat
    class SmallMultiHull extends DayBoat
    class PedalWheelBoat extends multi EngineLess, WheelBoat
    class SmallCatamaran extends SmallMultiHull
    class Pedalo extends multi PedalWheelBoat, SmallCatamaran

Hierarchy of classes with methods and constructors that use super.

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

Tests
-----

    describe 'multi', ->

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

        it 'calls super properly', ->
            obj = new D
            expect(mro D).toEqual [D, B, C, A, Object]
            expect(obj.method()).toBe "D>B>C>A"

        it 'gets constructed properly', ->
            obj = new D
            expect(obj.d).toBe 'd'
            expect(obj.c).toBe 'c'
            expect(obj.b).toBe 'b'
            expect(obj.a).toBe 'a'

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
