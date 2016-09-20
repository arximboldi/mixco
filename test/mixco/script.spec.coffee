# spec.mixco.value
# ================

# > This file is part of the [Mixco framework](http://sinusoid.es/mixco).
# > - **View me [on a static web](http://sinusoid.es/mixco/test/mixco/script.spec.html)**
# > - **View me [on GitHub](https://github.com/arximboldi/mixco/blob/master/test/mixco/script.spec.coffee)**

chai = {expect} = require 'chai'
{stub, spy} = require 'sinon'
chai.use require 'sinon-chai'

describe 'mixco.script', ->

    {isinstance} = require 'heterarchy'
    mixco = require 'mixco'
    {Script, register} = mixco.script
    control = mixco.control

    class TestScript extends Script
        __registeredName: 'testscript'

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

        testModule = null
        beforeEach ->
            testModule =
                exports: {}
                filename: 'testscript.mixco.js'

        it 'registers a class in the given NodeJs module', ->
            register testModule, TestScript
            expect(isinstance testModule.exports.testscript, TestScript)
                .to.be.true

        it 'can generate a script type from a definition', ->
            spier = stub
                constructor: spy()
                preinit: ->
                init: ->
                shutdown: ->
                postshutdown: ->
            register testModule,
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

            script = testModule.exports.testscript
            expect(script.name).to.be.eq 'testscript'
            expect(script.info.author).to.be.eq 'Jimmy Jazz'
            expect(spier.constructor).to.have.been.called

            script.init()
            expect(spier.preinit).to.have.been.called
            expect(spier.init).to.have.been.called

            script.shutdown()
            expect(spier.shutdown).to.have.been.called
            expect(spier.postshutdown).to.have.been.called

        it 'controls created during construction are registered autoamtically', ->
            expectedControls = []
            register testModule,
                constructor: ->
                    expectedControls.push control.input()
                    expectedControls.push control.control()

            expect(expectedControls.length)
                .to.be.eq 2
            expect(testModule.exports.testscript.controls)
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
