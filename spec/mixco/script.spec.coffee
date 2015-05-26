# spec.mixco.value
# ================

describe 'mixco.script', ->

    {isinstance} = require 'heterarchy'
    {Script, register} = require '../../src/script'
    control = require '../../src/control'

    class TestScript extends Script

    describe 'Script', ->

        script = null

        beforeEach ->
            script = new TestScript

        it 'configures controller id to be de script name', ->
            expect(script.config())
                .toMatch "<controller id=\"testscript\">[^$]*</controller>"

        it 'can generate configuration with partial metadata', ->
            delete script.info.wiki
            expect(script.config())
                .not.toContain "undefined"

    describe 'register', ->

        it 'registers a class in the given NodeJs module', ->
            testModule = exports: {}
            register testModule, TestScript
            expect(isinstance testModule.exports.testscript, TestScript)
                .toBe true

        it 'can generate a script type from a definition', ->
            spy = createSpyObj 'scriptSpy', [
                'constructor', 'preinit', 'init', 'shutdown', 'postshutdown' ]
            testModule = exports: {}

            register testModule,
                name: 'awesome_script'
                constructor: -> spy.constructor()
                preinit: ->
                    spy.preinit()
                    expect(@_isInit).not.toBeDefined()
                init: -> spy.init()
                postshutdown: ->
                    spy.postshutdown()
                    expect(@_isInit).not.toBeDefined()
                shutdown: -> spy.shutdown()
                info: author: 'Jimmy Jazz'

            script = testModule.exports.awesome_script
            expect(script.name).toBe 'awesome_script'
            expect(script.info.author).toBe 'Jimmy Jazz'
            expect(spy.constructor).toHaveBeenCalled()

            script.init()
            expect(spy.preinit).toHaveBeenCalled()
            expect(spy.init).toHaveBeenCalled()

            script.shutdown()
            expect(spy.shutdown).toHaveBeenCalled()
            expect(spy.postshutdown).toHaveBeenCalled()

        it 'controls created during construction are registered autoamtically', ->
            testModule = exports: {}
            expectedControls = []

            register testModule,
                name: 'some_script'
                constructor: ->
                    expectedControls.push control.knob()
                    expectedControls.push control.ledButton()

            expect(expectedControls.length)
                .toBe 2
            expect(testModule.exports.some_script.controls)
                .toEqual expectedControls

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
