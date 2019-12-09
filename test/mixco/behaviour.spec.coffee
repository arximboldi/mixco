# spec.mixco.behaviour
# ====================

# > This file is part of the [Mixco framework](http://sinusoid.es/mixco).
# > - **View me [on a static web](http://sinusoid.es/mixco/test/mixco/behaviour.spec.html)**
# > - **View me [on GitHub](https://github.com/arximboldi/mixco/blob/master/test/mixco/behaviour.spec.coffee)**

chai = {expect} = require 'chai'
{spy, stub, match} = require 'sinon'
chai.use require 'sinon-chai'

describe 'mixco.behaviour', ->

    {util, value, behaviour, transform} = mixco = require 'mixco'
    mocks = require '../mock'

    mockActor = -> stub
        doSend: ->
        send: ->
        on: ->
        addListener: ->
        removeListener: ->

    mockBehaviour = ->
        mocked = new behaviour.Behaviour arguments...
        spy mocked, 'enable'
        spy mocked, 'disable'
        spy mocked, 'onMidiEvent'
        mocked

    describe 'option', ->

        option = behaviour.option

        it 'has some linear transforms', ->
            expect(option.invert.transform 32).to.eq 95
            expect(option.spread64.transform 32).to.eq -32

        it 'has some non-linear transforms', ->
            expect(option.diff.transform 32, 8).to.eq 40
            expect(option.hercjog.transform 32, 8).to.eq 40

        it 'enables soft takeover on input mappings', ->
            beh = behaviour.mapIn "[Test]", "test"
            beh.script = mocks.testScript()

            option.softTakeover.enable beh
            expect(beh.script.mixxx.engine.softTakeover)
                .to.have.been.calledWith "[Test]", "test", true

            option.softTakeover.disable beh
            expect(beh.script.mixxx.engine.softTakeover)
                .to.have.been.calledWith "[Test]", "test", false

        it 'replaces dashes from option names', ->
            expect(option.invert.name).to.eq 'invert'
            expect(option.softTakeover.name).to.eq 'soft-takeover'


    describe 'Behaviour', ->

        behav = null
        beforeEach ->
            behav = mockBehaviour initial: 32

        it 'returns the same MIDI value as normal value', ->
            expect(behav.value).to.eq behav.midiValue
            expect(behav.value).to.eq 32

            behav.value = 64
            expect(behav.value).to.eq behav.midiValue
            expect(behav.value).to.eq 64

        it 'transforms MIDI input events with given options', ->
            behav.option transform: (x) -> x * 2
            actor = new behaviour.Actor
            behav.enable {}, actor

            actor.emit 'event', value: 3
            expect(behav.onMidiEvent).to.have.been.calledWith value: 6

            behav.option transform: (x) -> x - 1

            actor.emit 'event', value: 3
            expect(behav.onMidiEvent).to.have.been.calledWith value: 5

        it 'processes MIDI input events with given options', ->
            behav.option process: (ev, b) -> ev.value = ev.value * 2
            actor = new behaviour.Actor
            behav.enable {}, actor

            actor.emit 'event', value: 3
            expect(behav.onMidiEvent).to.have.been.calledWith value: 6

            behav.option process: (ev, b) -> ev.value = ev.value - b.midiValue
            actor.emit 'event', value: 3
            expect(behav.onMidiEvent).to.have.been.calledWith value: -26

        it 'transforms can use the previous value', ->
            opt = stub transform: ->
            behav.option opt

            actor = new behaviour.Actor
            behav.enable {}, actor

            actor.emit 'event', value: 3
            expect(opt.transform).to.have.been.calledWith 3, 32

        it 'options are enabled and disabled', ->
            opt = stub
                enable: ->
                disable: ->
            behav.option opt

            script = {}
            actor = new behaviour.Actor
            behav.enable script, actor
            expect(opt.enable).to.have.been.calledWith behav

            behav.disable script, actor
            expect(opt.disable).to.have.been.calledWith behav

        it 'can take options with an option chooser syntax', ->
            behav.options.spread64
            behav.options.softTakeover
            expect(behav._options).to.eql [
                behaviour.option.spread64
                behaviour.option.softTakeover
            ]


    describe 'Output', ->

        output = null
        actor  = null

        beforeEach ->
            output = new behaviour.Output
            actor  = mockActor()

        it 'can accept actor without "send"', ->
            actor.send = undefined
            output.enable {}, actor
            output.value = 5
            output.value = 0

        it 'initializes the actor depending on pre-enable value', ->
            output.output.value = 1
            output.enable {}, actor
            expect(actor.doSend).to.have.been.calledWith 'on'

        it 'initializes the actor even if it denies output', ->
            actor.send = undefined
            output.output.value = 1
            output.enable {}, actor
            expect(actor.doSend).to.have.been.calledWith 'on'

        it 'sends "on" value when value is above or equal minimum', ->
            output.enable {}, actor
            output.output.value = 1
            expect(actor.send).to.have.been.calledWith 'on'

        it 'sends "on" value when value is below minimum', ->
            output.enable {}, actor
            output.output.value = 1
            output.output.value = 0
            expect(actor.send).to.have.been.calledWith 'off'


    describe 'Transform', ->

        it 'can take an initial value as second parameter', ->
            t = behaviour.transform (->), 42
            expect(t.value).to.eq 42

        it 'sets its value and output to the transformed MIDI input', ->
            t = behaviour.transform (ev) -> ev.value * 2

            t.onMidiEvent value: 3
            expect(t.value).to.eq 6
            expect(t.output.value).to.eq 6
            expect(t.midiValue).to.eq 6

            t.onMidiEvent value: 6
            expect(t.value).to.eq 12
            expect(t.output.value).to.eq 12
            expect(t.midiValue).to.eq 12

        it 'can inverse the transform to reconstruct the midi values', ->
            f = (ev) -> ev.value * 2
            f.inverse = (v) -> v / 2
            t = behaviour.transform f

            t.onMidiEvent value: 3
            expect(t.value).to.eq 6
            expect(t.midiValue).to.eq 3

        it 'does not set its value when the transform gives a nully value', ->
            t = behaviour.transform (ev) -> if ev.value != 42 then ev.value * 2

            t.onMidiEvent value: 3
            expect(t.value).to.eq 6

            t.onMidiEvent value: 42
            expect(t.value).to.eq 6

            t.onMidiEvent value: 0
            expect(t.value).to.eq 0

        it 'can take binary transform that depend on pressed state', ->
            t = behaviour.transform transform.binaryT

            t.onMidiEvent pressed: true
            expect(t.value).to.be.true

            t.onMidiEvent pressed: true
            expect(t.value).to.be.false


    describe 'InMap', ->
        map    = null
        actor  = null
        script = null

        beforeEach ->
            map = behaviour.map
                group:  "[test]"
                key:    "test"
                initial: 42
            actor  = mockActor()
            script = mocks.testScript()

        it 'returns the value as midi value when not inversible transform', ->
            expect(map.value).to.eq map.midiValue
            expect(map.midiValue).to.eq 42

            map.value = 32
            expect(map.value).to.eq map.midiValue
            expect(map.midiValue).to.eq 32

        it 'uses the inverse of the transform to produce back the MIDI values', ->
            map.transform inverse: (x) -> x - 10

            expect(map.value).to.eq 42
            expect(map.midiValue).to.eq 32

            map.value = 32
            expect(map.value).to.eq 32
            expect(map.midiValue).to.eq 22


    describe 'Map', ->

        map2   = null
        map    = null
        actor  = null
        script = null

        beforeEach ->
            map    = behaviour.map "[Test]", "test"
            map2   = behaviour.map "[Test]", "test", "[Test2]", "test2"
            actor  = mockActor()
            script = mocks.testScript()

        it 'does not listen to the Mixxx control unnecesarily', ->
            actor.send = undefined
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .not.to.have.been.called

        it 'connects to the Mixxx control when actor has send', ->
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .to.have.been.calledWith "[Test]", "test", script.handlerKey()

        it 'connects to output control when different from input', ->
            map2.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .to.have.been.calledWith "[Test2]", "test2", script.handlerKey()

        it 'direct maps output to the right parameter', ->
            expect(map.directOutMapping()).to.eql {
                group: "[Test]",  key: "test", minimum: 1 }
            expect(map2.directOutMapping()).to.eql {
                 group: "[Test2]", key: "test2", minimum: 1 }

        it 'direct maps input to the right parameter', ->
            expect(map.directInMapping()).to.eql {
                group: "[Test]",  key: "test" }
            expect(map2.directInMapping()).to.eql {
                group: "[Test]",  key: "test" }

        it 'connects to the Mixxx control when someone is obsrving "value"', ->
            map.on "value", ->
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .to.have.been.calledWith "[Test]", "test", script.handlerKey()

        it 'initializes the value and output with the current engine status', ->
            script.mixxx.engine.getValue = (group, key) ->
                if group == "[Test]" and key == "test"
                    1
                else if group == "[Test2]" and key == "test2"
                    2
                else
                    null
            map2.enable script, actor
            expect(map2.value).to.eq(1)
            expect(map2.output.value).to.eq(2)

        it 'sets the values in the engine using the default transform', ->
            xfader = behaviour.map "[Master]", "crossfader"
            xfader.enable script, actor

            xfader.onMidiEvent value: 63.5
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Master]", "crossfader", 0.0

            xfader.onMidiEvent value: 127
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Master]", "crossfader", 1

            xfader.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Master]", "crossfader", 1

        it 'sets the values in the engine using custom transformation', ->
            xfader = behaviour.map("[Master]", "crossfader").transform (ev) -> ev.value
            xfader.enable script, actor

            xfader.onMidiEvent value: 64
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Master]", "crossfader", 64

            xfader.onMidiEvent value: 127
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Master]", "crossfader", 127

            xfader.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Master]", "crossfader", 0

        it 'does not direct map output when a custom transform is set', ->
            xfader = behaviour.map("[Master]", "crossfader").transform (v) -> v
            expect(xfader.directInMapping()).to.eq undefined

        it 'does not direct map input when a custom transform is set', ->
            xfader = behaviour.map("[Master]", "crossfader").meter (v) -> v
            expect(xfader.directOutMapping()).to.eq undefined

        it 'does nothing when the transform return null', ->
            xfader = behaviour.map("[Master]", "crossfader").transform (v) ->
                if v.value == 64 then 64 else null
            xfader.enable script, actor

            xfader.onMidiEvent value: 32
            expect(script.mixxx.engine.setValue)
                .not.to.have.been.called

            xfader.onMidiEvent value: 64
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Master]", "crossfader", 64

        it 'does toggle from previous state when binary transform', ->
            lock = behaviour.map "[Channel1]", "keylock"
            lock.enable script, actor

            lock.onMidiEvent pressed: true
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Channel1]", "keylock", true

            lock.onMidiEvent pressed: true
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Channel1]", "keylock", false


    describe 'Chooser', ->
        actor   = null
        script  = null
        chooser = null
        engine  = null

        beforeEach ->
            chooser = behaviour.chooser()
            actor   = mockActor()
            script  = mocks.testScript()
            engine  = script.mixxx.engine
            chooser.add "[Channel1]", "pfl"
            chooser.add "[Channel2]", "pfl"
            chooser.add "[Channel3]", "pfl"
            chooser.add "[Channel4]", "pfl"

        it "activates the right option, when chooser is enabled", ->
            chooser.enable script, actor

            chooser.activate 0
            expect(engine.getValue "[Channel1]", "pfl").to.be.true
            expect(engine.getValue "[Channel2]", "pfl").to.be.false

            chooser.activate 1
            expect(engine.getValue "[Channel1]", "pfl").to.be.false
            expect(engine.getValue "[Channel2]", "pfl").to.be.true

        it "activates the right option, when first activator is enabled", ->
            chooser.activator(0).enable script, actor
            chooser.activate 0
            expect(engine.getValue "[Channel1]", "pfl").to.be.true
            expect(engine.getValue "[Channel2]", "pfl").to.be.false

        it "activates the right option, when second activator is enabled", ->
            chooser.activator(1).enable script, actor
            chooser.activate 1
            expect(engine.getValue "[Channel1]", "pfl").to.be.false
            expect(engine.getValue "[Channel2]", "pfl").to.be.true

        it "activators activate when control pressed", ->
            chooser.activator(0).enable script, actor
            chooser.activator(1).enable script, actor

            chooser.activator(1).onMidiEvent pressed: true
            expect(engine.getValue "[Channel1]", "pfl").to.be.false
            expect(engine.getValue "[Channel2]", "pfl").to.be.true

            chooser.activator(0).onMidiEvent pressed: true
            expect(engine.getValue "[Channel1]", "pfl").to.be.true
            expect(engine.getValue "[Channel2]", "pfl").to.be.false

            chooser.activator(1).onMidiEvent pressed: false
            expect(engine.getValue "[Channel1]", "pfl").to.be.true
            expect(engine.getValue "[Channel2]", "pfl").to.be.false

        it "toggles the selected option on or off", ->
            chooser.enable script, actor
            chooser.activate 1
            expect(engine.getValue "[Channel1]", "pfl").to.be.false
            expect(engine.getValue "[Channel2]", "pfl").to.be.true
            chooser._updateValue() # simulate callback

            chooser.onMidiEvent pressed: true
            expect(engine.getValue "[Channel1]", "pfl").to.be.false
            expect(engine.getValue "[Channel2]", "pfl").to.be.false
            chooser._updateValue() # simulate callback

            chooser.onMidiEvent pressed: true
            expect(engine.getValue "[Channel1]", "pfl").to.be.false
            expect(engine.getValue "[Channel2]", "pfl").to.be.true

        it "connects and disconnects from controls", ->
            chooser.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .to.have.been.calledWith "[Channel1]", "pfl", match.string
            expect(script.mixxx.engine.connectControl)
                .to.have.been.calledWith "[Channel2]", "pfl", match.string

            chooser.disable script, actor
            expect(script.mixxx.engine.connectControl)
                .to.have.been.calledWith "[Channel1]", "pfl",
                    match.string, true
            expect(script.mixxx.engine.connectControl)
                .to.have.been.calledWith "[Channel2]", "pfl",
                    match.string, true

        it "initialzies its value to true", ->
            engine.setValue "[Channel1]", "pfl", true
            chooser.enable script, actor
            expect(chooser.value).to.be.true

        it "initialzies its value to false", ->
            chooser.enable script, actor
            expect(chooser.value).to.be.false

        it "can select with a selector knob", ->
            selector = chooser.selector()
            chooser.enable script, actor
            selector.enable script, actor
            chooser.activate 0
            chooser._updateValue()

            selector.onMidiEvent value: 32
            expect(engine.getValue "[Channel1]", "pfl").to.be.false
            expect(engine.getValue "[Channel2]", "pfl").to.be.true
            expect(engine.getValue "[Channel3]", "pfl").to.be.false
            expect(engine.getValue "[Channel4]", "pfl").to.be.false

            selector.onMidiEvent value: 80
            expect(engine.getValue "[Channel1]", "pfl").to.be.false
            expect(engine.getValue "[Channel2]", "pfl").to.be.false
            expect(engine.getValue "[Channel3]", "pfl").to.be.true
            expect(engine.getValue "[Channel4]", "pfl").to.be.false

            selector.onMidiEvent value: 120
            expect(engine.getValue "[Channel1]", "pfl").to.be.false
            expect(engine.getValue "[Channel2]", "pfl").to.be.false
            expect(engine.getValue "[Channel3]", "pfl").to.be.false
            expect(engine.getValue "[Channel4]", "pfl").to.be.true

        it "selector value is transformed back to MIDI", ->
            selector = chooser.selector()
            chooser.enable script, actor
            selector.enable script, actor
            chooser.activate 0
            chooser._updateValue()

            chooser.select 0
            chooser._updateValue()
            expect(selector.midiValue).to.eq 0

            chooser.select 1
            chooser._updateValue()
            expect(selector.midiValue).to.eq 32

            chooser.select 2
            chooser._updateValue()
            expect(selector.midiValue).to.eq 64

            chooser.select 3
            chooser._updateValue()
            expect(selector.midiValue).to.eq 96

        it "selector value keeps MIDI offset", ->
            selector = chooser.selector()
            chooser.enable script, actor
            selector.enable script, actor
            chooser.activate 0
            chooser._updateValue()

            selector.onMidiEvent value: 36
            expect(selector.midiValue).to.eq 36

            selector._updateValue 1
            expect(selector.midiValue).to.eq 36

        it "can select before or after being enabled", ->
            chooser.select 2
            chooser.enable script, actor

            chooser.onMidiEvent pressed: true
            expect(engine.getValue "[Channel1]", "pfl").to.be.false
            expect(engine.getValue "[Channel2]", "pfl").to.be.false
            expect(engine.getValue "[Channel3]", "pfl").to.be.true
            expect(engine.getValue "[Channel4]", "pfl").to.be.false

            chooser.select 1
            expect(engine.getValue "[Channel1]", "pfl").to.be.false
            expect(engine.getValue "[Channel2]", "pfl").to.be.true
            expect(engine.getValue "[Channel3]", "pfl").to.be.false
            expect(engine.getValue "[Channel4]", "pfl").to.be.false

        it "assumes engine keeps exclusivity with auto-exclusive", ->
            chooser = behaviour.chooser autoExclusive: true
            chooser.add "[Channel1]", "pfl"
            chooser.add "[Channel2]", "pfl"
            chooser.enable script, actor

            chooser.activate 1
            expect(engine.getValue "[Channel1]", "pfl").to.eq 0
            expect(engine.getValue "[Channel2]", "pfl").to.be.true

            chooser.activate 0
            expect(engine.getValue "[Channel1]", "pfl").to.be.true
            expect(engine.getValue "[Channel2]", "pfl").to.be.true

        it "calls onDisable to materialize disabling", ->
            spier = stub onDisable: ->
            chooser = behaviour.chooser onDisable: spier.onDisable
            chooser.add "[Channel1]", "pfl"
            chooser.add "[Channel2]", "pfl"
            chooser.enable script, actor

            chooser.onMidiEvent pressed: true
            expect(spier.onDisable).not.to.have.been.called

            chooser.value = true
            chooser.onMidiEvent pressed: true
            expect(spier.onDisable).to.have.been.called

        it "reads value from optional second key", ->
            chooser = behaviour.chooser()
            chooser.add "[Channel1]", "pfl", "listen"
            chooser.add "[Channel2]", "pfl", "listen"
            chooser.enable script, actor

            expect(script.mixxx.engine.connectControl)
                .not.to.have.been.calledWith "[Channel1]", "pfl", match.string
            expect(script.mixxx.engine.connectControl)
                .to.have.been.calledWith "[Channel1]", "listen", match.string

            engine.setValue "[Channel1]", "pfl", true
            chooser._updateValue()
            expect(chooser.value).to.be.false

            engine.setValue "[Channel1]", "pfl", false
            engine.setValue "[Channel1]", "listen", true
            chooser._updateValue()
            expect(chooser.value).to.be.true


    describe 'When', ->

        condition = null
        wrapped   = null
        when_     = null
        actor     = null
        script    = null

        beforeEach ->
            condition = value.value initial: false
            wrapped   = mockBehaviour()
            actor     = mockActor()
            script    = mocks.testScript()
            when_     = behaviour.when condition, wrapped

        it "does nothing when enabled and condition not satisfied", ->
            when_.enable script, actor
            expect(wrapped.enable).
                not.to.have.been.called

        it "enables wrapped when condition is satisfied", ->
            condition.value = true
            when_.enable script, actor
            expect(wrapped.enable).
                to.have.been.calledWith script, actor

        it "disables wrapped when it is disabled", ->
            condition.value = true
            when_.enable script, actor
            when_.disable script, actor
            expect(wrapped.disable).
                to.have.been.calledWith script, actor

        it "enables or disables wrapped when condition changes", ->
            when_.enable script, actor
            condition.value = true
            expect(wrapped.enable).
                to.have.been.calledWith script, actor
            condition.value = false
            expect(wrapped.disable).
                to.have.been.calledWith script, actor

        it "generates a new negated version on 'else", ->
            wrapped2 = mockBehaviour()
            else_ = when_.else wrapped2
            condition.value = true
            else_.enable script, actor
            expect(wrapped2.enable).
                not.to.have.been.calledWith script, actor
            condition.value = false
            expect(wrapped2.enable).
                to.have.been.calledWith script, actor

        it "else-when chains enable one branch exclusively", ->
            condition2 = value.value false
            wrapped2 = mockBehaviour()
            elseWhen_ = when_.else.when condition2, wrapped2

            wrapped3 = mockBehaviour()
            else_ = when_.else wrapped3

            when_.enable script, actor
            elseWhen_.enable script, actor
            else_.enable script, actor

            expect(wrapped.actor).not.to.exist
            expect(wrapped2.actor).not.to.exist
            expect(wrapped3.actor).to.exist

            condition.value = true
            expect(wrapped.actor).to.exist
            expect(wrapped2.actor).not.to.exist
            expect(wrapped3.actor).not.to.exist

            condition2.value = true
            expect(wrapped.actor).to.exist
            expect(wrapped2.actor).not.to.exist
            expect(wrapped3.actor).not.to.exist

            condition.value = false
            expect(wrapped.actor).not.to.exist
            expect(wrapped2.actor).to.exist
            expect(wrapped3.actor).not.to.exist

            condition2.value = false
            expect(wrapped.actor).not.to.exist
            expect(wrapped2.actor).not.to.exist
            expect(wrapped3.actor).to.exist

        it "exposes whether it meets the condition on its 'value'", ->
            when_.enable script, actor
            condition.value = true
            expect(when_.value).to.be.true
            condition.value = false
            expect(when_.value).to.be.false

        it "propagates options to the wrapped behaviour", ->
            when_.option behaviour.option.softTakeover
            expect(wrapped._options).to.eql [
                behaviour.option.softTakeover
            ]

            when_.option behaviour.option.invert
            expect(wrapped._options).to.eql [
                behaviour.option.softTakeover
                behaviour.option.invert
            ]


    describe 'PunchIn', ->

        rightPunchIn = null
        leftPunchIn  = null
        actor        = null
        script       = null
        xfader       = 0.0

        beforeEach ->
            leftPunchIn  = behaviour.punchIn 0.5
            rightPunchIn = behaviour.punchIn -0.5
            actor        = mockActor()
            script       = mocks.testScript()
            script.mixxx.engine.getValue = (group, control) ->
                expect(group).to.eq "[Master]"
                expect(control).to.eq "crossfader"
                xfader
            leftPunchIn.enable script, actor
            rightPunchIn.enable script, actor

        it "does nothing when the crossfader is to the requested side", ->
            xfader = -0.75
            leftPunchIn.onMidiEvent value: 1
            expect(script.mixxx.engine.setValue).not.to.have.been.called
            leftPunchIn.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue).not.to.have.been.called

            xfader = 0.75
            rightPunchIn.onMidiEvent value: 1
            expect(script.mixxx.engine.setValue).not.to.have.been.called
            rightPunchIn.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue).not.to.have.been.called

        it "sets the crossfader to the middle and restores otherwise", ->
            xfader = 0.75
            leftPunchIn.onMidiEvent pressed: true
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Master]", "crossfader", 0.0
            leftPunchIn.onMidiEvent pressed: false
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Master]", "crossfader", 0.75

            xfader = -0.75
            rightPunchIn.onMidiEvent pressed: true
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Master]", "crossfader", 0.0
            rightPunchIn.onMidiEvent pressed: false
            expect(script.mixxx.engine.setValue)
                .to.have.been.calledWith "[Master]", "crossfader", -0.75


    describe 'scratchEnable', ->

        actor   = null
        script  = null
        scratch = null

        beforeEach ->
            actor   = mockActor()
            script  = mocks.testScript()
            scratch = behaviour.scratchEnable 1, 32, 33, 1, 0.4, false
            scratch.enable script, actor

        it 'enables scratch on button press', ->
            expect(script.mixxx.engine.scratchEnable)
                .not.to.have.been.called

            scratch.onMidiEvent pressed: true
            expect(script.mixxx.engine.scratchEnable)
                .to.have.been.calledWith 1, 32, 33, 1, 0.4, false

        it 'disables scratch on button release', ->
            expect(script.mixxx.engine.scratchDisable)
                .not.to.have.been.called

            scratch.onMidiEvent value: 0
            expect(script.mixxx.engine.scratchEnable)
                .not.to.have.been.called
            expect(script.mixxx.engine.scratchDisable)
                .to.have.been.calledWith 1, false


    describe 'scratchTick', ->

        actor   = null
        script  = null
        scratch = null

        beforeEach ->
            actor   = mockActor()
            script  = mocks.testScript()
            scratch = behaviour.scratchTick 1, (v) -> v / 2
            scratch.enable script, actor

        it 'ticks the given deck scratch with the current transform', ->
            expect(script.mixxx.engine.scratchTick)
                .not.to.have.been.called

            scratch.onMidiEvent value: 64
            expect(script.mixxx.engine.scratchTick)
                .to.have.been.calledWith 1, 32

            scratch.onMidiEvent value: 32
            expect(script.mixxx.engine.scratchTick)
                .to.have.been.calledWith 1, 16

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
