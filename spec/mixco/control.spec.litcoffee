spec.mixco.behaviour
====================

Tests for behaviours.

Mocks
-----

    mock = require '../mock'


Module
------

    {Control} = require '../../mixco/control'

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
