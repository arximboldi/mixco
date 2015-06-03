# spec.mixco.behaviour
# ====================

chai = {expect} = require 'chai'
{spy, mock} = require 'sinon'
chai.use require 'sinon-chai'

describe 'mixco.control', ->

    {union} = require 'underscore'
    mocks = require '../mock'
    mixco = require 'mixco'
    c = {MIDI_CC, Control, InControl, OutControl} = mixco.control
    {Behaviour} = behaviour = mixco.behaviour

    describe 'Control', ->

        control = null

        beforeEach ->
            control = new Control

        it "exposes script when initialized", ->
            script = new mocks.TestScript "script"

            control.init script
            expect(control.script).to.eq script

            control.shutdown script
            expect(control.script).not.to.exist

        it "converts number or pair in constructor to CC midi id", ->
            control = new Control 32
            expect(control.ids.length).to.eq 1
            {message, midino, channel} = control.ids[0]
            expect([message, midino, channel]).to.eql [MIDI_CC, 32, 0]

            control = new Control 64, 8
            expect(control.ids.length).to.eq 1
            {message, midino, channel} = control.ids[0]
            expect([message, midino, channel]).to.eql [MIDI_CC, 64, 8]


    describe 'InControl', ->

        control = null

        beforeEach ->
            control = new InControl

        it "propagates options to its behaviours that are registered", ->
            beh1 = new Behaviour
            control.does beh1
            control.option behaviour.option.invert
            expect(beh1._options).to.eql [behaviour.option.invert]

        it "propagates options to its new behaviours", ->
            beh1 = new Behaviour
            control.option behaviour.option.invert
            control.does beh1
            expect(beh1._options).to.eql [behaviour.option.invert]

        it "propagates options to its conditional behaviours", ->
            beh1 = new Behaviour
            beh2 = new Behaviour
            beh3 = new Behaviour
            control.option behaviour.option.invert

            control.when new Behaviour, beh1
            expect(beh1._options).to.eql [behaviour.option.invert]

            control.else.when new Behaviour, beh2
            expect(beh2._options).to.eql [behaviour.option.invert]

            control.else beh3
            expect(beh3._options).to.eql [behaviour.option.invert]

        it "configures the options of its behaviour when it can", ->
            beh1 = new Behaviour
            beh1.directInMapping = ->
                group: "[master]"
                key: "crossfader"
            beh1.option behaviour.option.invert
            beh1.options.softTakeover
            control.does beh1

            expect(control.configInputs 0)
                .to.match ///
                    \s*<options>
                    \s*<invert/>
                    \s*<soft-takeover/>
                    \s*</options>
                ///

        it "configures as script binding when no direct input mapping", ->
            beh1 = new Behaviour
            beh1.option behaviour.option.invert
            beh1.option behaviour.option.softTakeover
            control.does beh1

            expect(control.configInputs 0, mocks.testScript())
                .to.match ///
                    \s*<options>
                    \s*<script-binding/>
                    \s*</options>
                ///

        it "configures as script binding when too many behaviours", ->
            beh1 = new Behaviour
            beh1.directInMapping = ->
                group: "[master]"
                key: "crossfader"
            beh2 = new Behaviour
            beh2.directInMapping = beh1.directInMapping

            beh1.option behaviour.option.invert
            beh1.options.softTakeover
            control.does beh1
            control.does beh2

            expect(control.configInputs 0, mocks.testScript())
                .to.match ///
                    \s*<options>
                    \s*<script-binding/>
                    \s*</options>
                ///

        it "configures as script binding when option without name", ->
            beh1 = new Behaviour
            beh1.directInMapping = ->
                group: "[master]"
                key: "crossfader"
            control.does beh1.option {}

            expect(control.configInputs 0, mocks.testScript())
                .to.match ///
                    \s*<options>
                    \s*<script-binding/>
                    \s*</options>
                ///

        it "configures as normal when no options", ->
            beh1 = new Behaviour
            beh1.directInMapping = ->
                group: "[master]"
                key: "crossfader"
            control.does beh1

            expect(control.configInputs 0, mocks.testScript())
                .to.match ///
                    \s*<options>
                    \s*<normal/>
                    \s*</options>
                ///


    describe 'OutControl', ->

        it "configures minimum and maximum from the behaviour mapping", ->
            control = new OutControl
            behave  = new Behaviour
            control.does behave

            behave.directOutMapping = ->
                minimum: 1
                maximum: 2
            config = control.configOutputs 0
            expect(config).to.contain("<minimum>1</minimum>")
            expect(config).to.contain("<maximum>2</maximum>")

            behave.directOutMapping = -> {}
            config = control.configOutputs 0
            expect(config).not.to.contain("<minimum>")
            expect(config).not.to.contain("<maximum>")

         it "configures an output for every midi id that is not a note off", ->
             control = new OutControl union c.ccIds(0x42), c.noteIds(0x33)
             behave  = new Behaviour
             control.does behave

             behave.directOutMapping = -> {}
             config = control.configOutputs 0
             expect(config).to.match ///
                     \s*<status>0xb0</status>
                     \s*<midino>0x42</midino>
                 ///
             expect(config).to.match ///
                     \s*<status>0x90</status>
                     \s*<midino>0x33</midino>
                 ///
             expect(config).not.to.match ///
                     \s*<status>0x80</status>
                     \s*<midino>0x33</midino>
                 ///

        it "turns off completely the controls on shut down", ->
            script = new mocks.TestScript "script"
            control = new OutControl
            spy(control, 'doSend')

            control.init script
            expect(control.doSend).not.to.have.been.calledWith 'disable'
            control.shutdown script
            expect(control.doSend).to.have.been.calledWith 'disable'

        it "sends midi to all outputs that are not a note off", ->
            script = new mocks.TestScript "script"
            control = new OutControl union c.ccIds(0x42), c.noteIds(0x33)

            control.init script
            control.doSend 'on'

            expect(script.mixxx.midi.sendShortMsg)
                .to.have.been.calledWith control.ids[0].status(),
                                      control.ids[0].midino,
                                      0x7f
            expect(script.mixxx.midi.sendShortMsg)
                .to.have.been.calledWith control.ids[1].status(),
                                      control.ids[1].midino,
                                      0x7f
            expect(script.mixxx.midi.sendShortMsg)
                .not
                .to.have.been.calledWith control.ids[2].status(),
                                      control.ids[2].midino,
                                      0x7f

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
