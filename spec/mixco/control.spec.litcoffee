spec.mixco.behaviour
====================

Tests for behaviours.

Mocks
-----

    mock = require '../mock'


Module
------

    {MIDI_CC, Control} = require '../../mixco/control'

Tests
-----

Tests for the **Control** base class.

    describe 'Control', ->

        control = null

        beforeEach ->
            control = new Control

        it "exposes script when initialized", ->
            script = new mock.TestScript "script"

            control.init script
            expect(control.script).toBe(script)

            control.shutdown script
            expect(control.script).not.toBeDefined()

        it "converts number or pair in constructor to CC midi id", ->
            control = new Control 32
            expect(control.ids.length).toBe(1)
            {message, midino, channel} = control.ids[0]
            expect([message, midino, channel]).toEqual [MIDI_CC, 32, 0]

            control = new Control 64, 8
            expect(control.ids.length).toBe(1)
            {message, midino, channel} = control.ids[0]
            expect([message, midino, channel]).toEqual [MIDI_CC, 64, 8]

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
