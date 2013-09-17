spec.mixco.behaviour
====================

Tests for behaviours.

Module
------

    util      = require '../../mixco/util'
    value     = require '../../mixco/value'
    behaviour = require '../../mixco/behaviour'

Mocks
-----

    mock = require '../mock'

    mockActor = -> createSpyObj 'actor', [
        'send',
        'on',
        'addListener',
        'removeListener' ]

    mockBehaviour = ->
        mocked = new behaviour.Behaviour arguments...
        spyOn(mocked, 'enable').andCallThrough()
        spyOn(mocked, 'disable').andCallThrough()
        spyOn(mocked, 'onMidiEvent').andCallThrough()
        mocked


Tests
-----

Tests for the **Behaviour** base class.

    describe 'Behaviour', ->

        behav = null
        beforeEach ->
            behav = mockBehaviour initial: 32

        it 'returns the same MIDI value as normal value', ->
            expect(behav.value).toBe behav.midiValue
            expect(behav.value).toBe 32

            behav.value = 64
            expect(behav.value).toBe behav.midiValue
            expect(behav.value).toBe 64

        it 'processes MIDI input events with given options', ->
            behav.option transform: (x) -> x * 2

            actor = new behaviour.Actor
            behav.enable {}, actor

            actor.emit 'event', value: 3
            expect(behav.onMidiEvent).toHaveBeenCalledWith value: 6

            behav.option transform: (x) -> x - 1

            actor.emit 'event', value: 3
            expect(behav.onMidiEvent).toHaveBeenCalledWith value: 5

        it 'transforms can use the current behaviour', ->
            opt = createSpyObj 'option', ['transform']
            behav.option opt

            actor = new behaviour.Actor
            behav.enable {}, actor

            actor.emit 'event', value: 3
            expect(opt.transform).toHaveBeenCalledWith 3, behav

        it 'options are enabled and disabled', ->
            opt = createSpyObj 'option', ['enable', 'disable']
            behav.option opt

            script = {}
            actor = new behaviour.Actor
            behav.enable script, actor
            expect(opt.enable).toHaveBeenCalledWith behav

            behav.disable script, actor
            expect(opt.disable).toHaveBeenCalledWith behav

Tests for the **Output** basic behaviour.

    describe 'Output', ->

        output = null
        actor  = null

        beforeEach ->
            output = new behaviour.Output
            actor  = do mockActor

        it 'can accept actor without "send"', ->
            actor.send = undefined
            output.enable {}, actor
            output.value = 5
            output.value = 0

        it 'initializes the actor depending on pre-enable value', ->
            output.output.value = 1
            output.enable {}, actor
            expect(actor.send).toHaveBeenCalledWith 'on'

        it 'sends "on" value when value is above or equal minimum', ->
            output.enable {}, actor
            output.output.value = 1
            expect(actor.send).toHaveBeenCalledWith 'on'

        it 'sends "on" value when value is bellow minimum', ->
            output.enable {}, actor
            output.output.value = 1
            output.output.value = 0
            expect(actor.send).toHaveBeenCalledWith 'off'

Tests for the **InMap** behaviour.

    describe 'InMap', ->
        map    = null
        actor  = null
        script = null

        beforeEach ->
            map = behaviour.map
                group:  "[test]"
                key:    "test"
                initial: 42
            actor = do mockActor
            script = do mock.testScript

        it 'returns the value as midi value when not inversible transform', ->
            expect(map.value).toBe map.midiValue
            expect(map.midiValue).toBe 42

            map.value = 32
            expect(map.value).toBe map.midiValue
            expect(map.midiValue).toBe 32

        it 'uses the inverse of the transform to produce back the MIDI values', ->
            map.transform inverse: (x) -> x - 10

            expect(map.value).toBe 42
            expect(map.midiValue).toBe 32

            map.value = 32
            expect(map.value).toBe 32
            expect(map.midiValue).toBe 22

Tests for the **Map** behaviour.

    describe 'Map', ->

        map2   = null
        map    = null
        actor  = null
        script = null

        beforeEach ->
            map    = behaviour.map "[Test]", "test"
            map2   = behaviour.map "[Test]", "test", "[Test2]", "test2"
            actor  = do mockActor
            script = do mock.testScript

        it 'does not listen to the Mixxx control unnecesarily', ->
            actor.send = undefined
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .not.toHaveBeenCalled()

        it 'connects to the Mixxx control when actor has send', ->
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Test]", "test", do script.handlerKey

        it 'connects to output control when different from input', ->
            map2.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Test2]", "test2", do script.handlerKey

        it 'direct maps output to the right parameter', ->
            expect(map.directOutMapping()).toEqual {
                group: "[Test]",  key: "test", minimum: 1 }
            expect(map2.directOutMapping()).toEqual {
                 group: "[Test2]", key: "test2", minimum: 1 }

        it 'direct maps input to the right parameter', ->
            expect(map.directInMapping()).toEqual { group: "[Test]",  key: "test" }
            expect(map2.directInMapping()).toEqual { group: "[Test]",  key: "test" }

        it 'connects to the Mixxx control when someone is obsrving "value"', ->
            map.on "value", ->
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Test]", "test", do script.handlerKey

        it 'initializes the value and output with the current engine status', ->
            script.mixxx.engine.getValue = (group, key) ->
                if group == "[Test]" and key == "test"
                    1
                else if group == "[Test2]" and key == "test2"
                    2
                else
                    null
            map2.enable script, actor
            expect(map2.value).toBe(1)
            expect(map2.output.value).toBe(2)

        it 'sets the values in the engine using the default transform', ->
            xfader = behaviour.map "[Master]", "crossfader"
            xfader.enable script, actor

            xfader.onMidiEvent value: 63.5
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0.0

            xfader.onMidiEvent value: 127
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 1

            xfader.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 1

        it 'sets the values in the engine using custom transformation', ->
            xfader = behaviour.map("[Master]", "crossfader").transform (v) -> v
            xfader.enable script, actor

            xfader.onMidiEvent value: 64
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 64

            xfader.onMidiEvent value: 127
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 127

            xfader.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0

        it 'does not direct map output when a custom transform is set', ->
            xfader = behaviour.map("[Master]", "crossfader").transform (v) -> v
            expect(do xfader.directInMapping).toBe undefined

        it 'does not direct map input when a custom transform is set', ->
            xfader = behaviour.map("[Master]", "crossfader").meter (v) -> v
            expect(do xfader.directOutMapping).toBe undefined

        it 'does nothing when the transform return null', ->
            xfader = behaviour.map("[Master]", "crossfader").transform (v) ->
                if v == 64 then 64 else null
            xfader.enable script, actor

            xfader.onMidiEvent value: 32
            expect(script.mixxx.engine.setValue)
                .not.toHaveBeenCalled()

            xfader.onMidiEvent value: 64
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 64

        it 'does toggle from previous state when binary transform', ->
            lock = behaviour.map "[Channel1]", "keylock"
            lock.enable script, actor

            lock.onMidiEvent value: 32
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Channel1]", "keylock", true

            lock.onMidiEvent value: 32
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Channel1]", "keylock", false


Tests for the **When** behaviour

    describe 'When', ->

        condition = null
        wrapped   = null
        when_     = null
        actor     = null
        script    = null

        beforeEach ->
            condition = value.value false
            wrapped   = do mockBehaviour
            actor     = do mockActor
            script    = do mock.testScript
            when_     = behaviour.when condition, wrapped

        it "does nothing when enabled and condition not satisifed", ->
            when_.enable script, actor
            expect(wrapped.enable).
                not.toHaveBeenCalled()

        it "enables wrapped when condition is satisfied", ->
            condition.value = true
            when_.enable script, actor
            expect(wrapped.enable).
                toHaveBeenCalledWith script, actor

        it "disables wrapped when it is disabled", ->
            condition.value = true
            when_.enable script, actor
            when_.disable script, actor
            expect(wrapped.disable).
                toHaveBeenCalledWith script, actor

        it "enables or disables wrapped when condition changes", ->
            when_.enable script, actor
            condition.value = true
            expect(wrapped.enable).
                toHaveBeenCalledWith script, actor
            condition.value = false
            expect(wrapped.disable).
                toHaveBeenCalledWith script, actor

        it "generates a new negated version on 'else", ->
            wrapped2 = do mockBehaviour
            else_ = when_.else wrapped2
            condition.value = true
            else_.enable script, actor
            expect(wrapped2.enable).
                not.toHaveBeenCalledWith script, actor
            condition.value = false
            expect(wrapped2.enable).
                toHaveBeenCalledWith script, actor

        it "exposes wether it meets the condition on its 'value'", ->
            when_.enable script, actor
            condition.value = true
            expect(when_.value).toBe true
            condition.value = false
            expect(when_.value).toBe false


Tests for the **PunchIn** behaviour

    describe 'PunchIn', ->

        rightPunchIn = null
        leftPunchIn  = null
        actor        = null
        script       = null
        xfader       = 0.0

        beforeEach ->
            leftPunchIn  = behaviour.punchIn 0.5
            rightPunchIn = behaviour.punchIn -0.5
            actor        = do mockActor
            script       = do mock.testScript
            script.mixxx.engine.getValue = (group, control) ->
                expect(group).toBe "[Master]"
                expect(control).toBe "crossfader"
                xfader
            leftPunchIn.enable script, actor
            rightPunchIn.enable script, actor

        it "does nothing when the crossfader is to the requested side", ->
            xfader = -0.75
            leftPunchIn.onMidiEvent value: 1
            do expect(script.mixxx.engine.setValue).not.toHaveBeenCalled
            leftPunchIn.onMidiEvent value: 0
            do expect(script.mixxx.engine.setValue).not.toHaveBeenCalled

            xfader = 0.75
            rightPunchIn.onMidiEvent value: 1
            do expect(script.mixxx.engine.setValue).not.toHaveBeenCalled
            rightPunchIn.onMidiEvent value: 0
            do expect(script.mixxx.engine.setValue).not.toHaveBeenCalled

        it "sets the crossfader to the middle and restores otherwise", ->
            xfader = 0.75
            leftPunchIn.onMidiEvent value: 1
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0.0
            leftPunchIn.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0.75

            xfader = -0.75
            rightPunchIn.onMidiEvent value: 1
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0.0
            rightPunchIn.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", -0.75


Tests for the **scratchEnable** behaviour

    describe 'scratchEnable', ->

        actor   = null
        script  = null
        scratch = null

        beforeEach ->
            actor   = do mockActor
            script  = do mock.testScript
            scratch = behaviour.scratchEnable 1, 32, 33, 1, 0.4, false
            scratch.enable script, actor

        it 'enables scratch on button press', ->
            do expect(script.mixxx.engine.scratchEnable)
                .not.toHaveBeenCalled

            scratch.onMidiEvent value: 1
            expect(script.mixxx.engine.scratchEnable)
                .toHaveBeenCalledWith 1, 32, 33, 1, 0.4, false

        it 'disables scratch on button release', ->
            do expect(script.mixxx.engine.scratchDisable)
                .not.toHaveBeenCalled

            scratch.onMidiEvent value: 0
            do expect(script.mixxx.engine.scratchEnable)
                .not.toHaveBeenCalled
            expect(script.mixxx.engine.scratchDisable)
                .toHaveBeenCalledWith 1, false


Tests for the **scratchTick** behaviour

    describe 'scratchTick', ->

        actor   = null
        script  = null
        scratch = null

        beforeEach ->
            actor   = do mockActor
            script  = do mock.testScript
            scratch = behaviour.scratchTick 1, (v) -> v / 2
            scratch.enable script, actor

        it 'ticks the given deck scratch with the current transform', ->
            do expect(script.mixxx.engine.scratchTick)
                .not.toHaveBeenCalled

            scratch.onMidiEvent value: 64
            expect(script.mixxx.engine.scratchTick)
                .toHaveBeenCalledWith 1, 32

            scratch.onMidiEvent value: 32
            expect(script.mixxx.engine.scratchTick)
                .toHaveBeenCalledWith 1, 16

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
