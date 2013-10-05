spec.mixco.value
================

Tests for the `mixco.value` module.

    {isinstance} = require '../../mixco/multi'
    {Script, register} = require '../../mixco/script'

    class TestScript extends Script

Tests
-----

Script class.

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

Script registration.

    describe 'register', ->

        it 'registers a class in the given NodeJs module', ->
            testModule = exports: {}
            register testModule, TestScript
            expect(isinstance testModule.exports.testscript, TestScript)
                .toBe true

        it 'can generate a script type from a definition', ->
            spy = createSpyObj 'scriptSpy', [
                'constructor', 'preinit', 'init', 'shutdown' ]
            testModule = exports: {}

            register testModule,
                name: 'awesome_script'
                constructor: -> spy.constructor()
                preinit: ->
                    spy.preinit()
                    expect(@_isInit).not.toBeDefined()
                init: -> spy.init()
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
