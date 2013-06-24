spec.mixco.value
================

Tests for the `mixco.value` module.

Module
------

    {Script} = require '../../mixco/script'


Mocks
-----

    class TestScript extends Script

Tests
-----

    describe 'Script', ->

        script = null

        beforeEach ->
            script = new TestScript

        it 'configures controller id to be de script name', ->
            expect(script.config())
                .toMatch "<controller id=\"testscript\">[^$]*</controller>"
