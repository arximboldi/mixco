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
        mocked = new behaviour.Behaviour
        spyOn(mocked, 'enable').andCallThrough()
        spyOn(mocked, 'disable').andCallThrough()
        mocked


Tests
-----

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

Tests for the **Map** behaviour

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
            expect(map.directOutMapping()).toEqual { group: "[Test]",  key: "test" }
            expect(map2.directOutMapping()).toEqual { group: "[Test2]", key: "test2" }

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

            xfader.onEvent value: 63.5
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0.0

            xfader.onEvent value: 127
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 1

            xfader.onEvent value: 0
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 1

        it 'sets the values in the engine using custom transformation', ->
            xfader = behaviour.map("[Master]", "crossfader").transform (v) -> v
            xfader.enable script, actor

            xfader.onEvent value: 64
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 64

            xfader.onEvent value: 127
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 127

            xfader.onEvent value: 0
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0

        it 'does not direct map when a custom transform is set', ->
            xfader = behaviour.map("[Master]", "crossfader").transform (v) -> v
            expect(do xfader.directInMapping).toBe null


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
            leftPunchIn.onEvent value: 1
            do expect(script.mixxx.engine.setValue).not.toHaveBeenCalled
            leftPunchIn.onEvent value: 0
            do expect(script.mixxx.engine.setValue).not.toHaveBeenCalled

            xfader = 0.75
            rightPunchIn.onEvent value: 1
            do expect(script.mixxx.engine.setValue).not.toHaveBeenCalled
            rightPunchIn.onEvent value: 0
            do expect(script.mixxx.engine.setValue).not.toHaveBeenCalled

        it "sets the crossfader to the middle and restores otherwise", ->
            xfader = 0.75
            leftPunchIn.onEvent value: 1
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0.0
            leftPunchIn.onEvent value: 0
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0.75

            xfader = -0.75
            rightPunchIn.onEvent value: 1
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0.0
            rightPunchIn.onEvent value: 0
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", -0.75


Tests for the **ScratchEnable** behaviour

    describe 'ScratchEnable', ->

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

            scratch.onEvent value: 1
            expect(script.mixxx.engine.scratchEnable)
1                .toHaveBeenCalledWith 1, 32, 33, 1, 0.4, false

        it 'disables scratch on button release', ->
            do expect(script.mixxx.engine.scratchDisable)
                .not.toHaveBeenCalled

            scratch.onEvent value: 0
            do expect(script.mixxx.engine.scratchEnable)
                .not.toHaveBeenCalled
            expect(script.mixxx.engine.scratchDisable)
                .toHaveBeenCalledWith 1, false


Tests for the **ScratchTick** behaviour

    describe 'ScratchTick', ->

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

            scratch.onEvent value: 64
            expect(script.mixxx.engine.scratchTick)
                .toHaveBeenCalledWith 1, 32

            scratch.onEvent value: 32
            expect(script.mixxx.engine.scratchTick)
                .toHaveBeenCalledWith 1, 16
