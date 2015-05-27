# spec.mixco.value
# ================

chai = {expect} = require 'chai'
{stub} = require 'sinon'
chai.use require 'sinon-chai'

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
                .to.match /<controller id=\"testscript\">[^$]*<\/controller>/

        it 'can generate configuration with partial metadata', ->
            delete script.info.wiki
            expect(script.config())
                .not.to.contain "undefined"

    describe 'register', ->

        it 'registers a class in the given NodeJs module', ->
            testModule = exports: {}
            register testModule, TestScript
            expect(isinstance testModule.exports.testscript, TestScript)
                .to.be.true

        it 'can generate a script type from a definition', ->
            spier = stub
                constructor: ->
                preinit: ->
                init: ->
                shutdown: ->
                postshutdown: ->
            testModule = exports: {}

            register testModule,
                name: 'awesome_script'
                constructor: -> spier.constructor()
                preinit: ->
                    spier.preinit()
                    expect(@_isInit).not.to.exist
                init: -> spier.init()
                postshutdown: ->
                    spier.postshutdown()
                    expect(@_isInit).not.to.exist
                shutdown: -> spier.shutdown()
                info: author: 'Jimmy Jazz'

            script = testModule.exports.awesome_script
            expect(script.name).to.be.eq 'awesome_script'
            expect(script.info.author).to.be.eq 'Jimmy Jazz'
            expect(spier.constructor).to.have.been.called

            script.init()
            expect(spier.preinit).to.have.been.called
            expect(spier.init).to.have.been.called

            script.shutdown()
            expect(spier.shutdown).to.have.been.called
            expect(spier.postshutdown).to.have.been.called

        it 'controls created during construction are registered autoamtically', ->
            testModule = exports: {}
            expectedControls = []

            register testModule,
                name: 'some_script'
                constructor: ->
                    expectedControls.push control.knob()
                    expectedControls.push control.ledButton()

            expect(expectedControls.length)
                .to.be.eq 2
            expect(testModule.exports.some_script.controls)
                .to.eql expectedControls

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
