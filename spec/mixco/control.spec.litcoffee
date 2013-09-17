spec.mixco.behaviour
====================

Tests for behaviours.

Mocks
-----

    mock = require '../mock'


Module
------

    {MIDI_CC, Control, InControl, OutControl} = require '../../mixco/control'
    {Behaviour} = behaviour = require '../../mixco/behaviour'

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


Tests for the **InControl** class.

    describe 'InControl', ->

        control = null

        beforeEach ->
            control = new InControl

        it "propagates options to its behaviours that are registered", ->
            beh1 = new Behaviour
            control.does beh1
            control.option behaviour.option.invert
            expect(beh1._options).toEqual [behaviour.option.invert]

        it "propagates options to its new behaviours", ->
            beh1 = new Behaviour
            control.option behaviour.option.invert
            control.does beh1
            expect(beh1._options).toEqual [behaviour.option.invert]

        it "propagates options to its conditional behaviours", ->
            beh1 = new Behaviour
            beh2 = new Behaviour
            beh3 = new Behaviour
            control.option behaviour.option.invert

            control.when new Behaviour, beh1
            expect(beh1._options).toEqual [behaviour.option.invert]

            control.else.when new Behaviour, beh2
            expect(beh2._options).toEqual [behaviour.option.invert]

            control.else beh3
            expect(beh3._options).toEqual [behaviour.option.invert]

        it "configures the options of its behaviour when it can", ->
            beh1 = new Behaviour
            beh1.directInMapping = ->
                group: "[master]"
                key: "crossfader"
            beh1.option behaviour.option.invert
            beh1.option behaviour.option.softTakeover
            control.does beh1

            expect(control.configInputs 0)
                .toMatch ///
                    \s*<options>
                    \s*<invert/>
                    \s*<soft-takeover/>
                    \s*</options>
                ///

        it "configures as script binding when no direct input mapping", ->
            beh1 = new Behaviour
            beh1.option behaviour.option.invert
            beh1.option behaviour.option.softTakeover
            control.does beh1

            expect(control.configInputs 0, mock.testScript())
                .toMatch ///
                    \s*<options>
                    \s*<script-binding/>
                    \s*</options>
                ///

        it "configures as script binding when too many behaviours", ->
            beh1 = new Behaviour
            beh1.directInMapping = ->
                group: "[master]"
                key: "crossfader"
            beh2 = new Behaviour
            beh2.directInMapping = beh1.directInMapping

            beh1.option behaviour.option.invert
            beh1.option behaviour.option.softTakeover
            control.does beh1
            control.does beh2

            expect(control.configInputs 0, mock.testScript())
                .toMatch ///
                    \s*<options>
                    \s*<script-binding/>
                    \s*</options>
                ///

        it "configures as normal when no options", ->
            beh1 = new Behaviour
            beh1.directInMapping = ->
                group: "[master]"
                key: "crossfader"
            control.does beh1

            expect(control.configInputs 0, mock.testScript())
                .toMatch ///
                    \s*<options>
                    \s*<normal/>
                    \s*</options>
                ///


Tests for the **OutControl** class.

    describe 'OutControl', ->

        it "configures minimum and maximum from the behaviour mapping", ->
            control = new OutControl
            behave  = new Behaviour
            control.does behave

            behave.directOutMapping = ->
                minimum: 1
                maximum: 2
            expect(control.configOutputs 0)
                .toContain("<minimum>1</minimum>")
            expect(control.configOutputs 0)
                .toContain("<maximum>2</maximum>")

            behave.directOutMapping = -> {}
            expect(control.configOutputs 0)
                .not.toContain("<minimum>")
            expect(control.configOutputs 0)
                .not.toContain("<maximum>")

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
