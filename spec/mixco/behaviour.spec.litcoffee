spec.mixco.behaviour
====================

Tests for behaviours.

Mocks
-----

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

Tests for the output basic behaviour.

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
