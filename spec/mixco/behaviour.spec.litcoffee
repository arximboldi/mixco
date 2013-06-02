spec.mixco.behaviour
====================

Tests for behaviours.

Mocks
-----

    mock = require '../mock'

    mockActor = -> createSpyObj 'actor', [
        'send',
        'on',
        'addListener',
        'removeListener' ]

Module
------

    {Output, Map} = require '../../mixco/behaviour'


Tests
-----

Tests for the **Output** basic behaviour.

    describe 'Output', ->

        output = null
        actor  = null

        beforeEach ->
            output = new Output
            actor  = do mockActor

        it 'can accept actor without "send"', ->
            actor.send = undefined
            output.enable {}, actor
            output.value = 5
            output.value = 0

        it 'initializes the actor depending on pre-enable value', ->
            output.value = 1
            output.enable {}, actor
            expect(actor.send).toHaveBeenCalledWith 'on'

        it 'sends "on" value when value is above or equal minimum', ->
            output.enable {}, actor
            output.value = 1
            expect(actor.send).toHaveBeenCalledWith 'on'

        it 'sends "on" value when value is bellow minimum', ->
            output.enable {}, actor
            output.value = 1
            output.value = 0
            expect(actor.send).toHaveBeenCalledWith 'off'

Tests for the **Map** behaviour

    describe 'Map', ->

        map    = null
        actor  = null
        script = null

        beforeEach ->
            map    = new Map "[Test]", "test"
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


        it 'connects to the Mixxx control when someone is obsrving "value"', ->
            map.on "value", ->
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Test]", "test", do script.handlerKey
