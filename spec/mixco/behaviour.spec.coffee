# spec.mixco.behaviour
# ====================

describe 'mixco.behaviour', ->

    util      = require '../../mixco/util'
    value     = require '../../mixco/value'
    behaviour = require '../../mixco/behaviour'
    transform = require '../../mixco/transform'

    mock = require '../mock'

    mockActor = -> createSpyObj 'actor', [
        'doSend',
        'send',
        'on',
        'addListener',
        'removeListener' ]

    mockBehaviour = ->
        mocked = new behaviour.Behaviour arguments...
        spyOn(mocked, 'enable').andCallThrough()
        spyOn(mocked, 'disable').andCallThrough()
        spyOn(mocked, 'onMidiEvent').andCallThrough()
        mocked


    describe 'option', ->

        option = behaviour.option

        it 'has some linear transforms', ->
            expect(option.invert.transform 32).toBe 95
            expect(option.spread64.transform 32).toBe -32

        it 'has some non-linear transforms', ->
            expect(option.diff.transform 32, 8).toBe 40
            expect(option.hercjog.transform 32, 8).toBe 40

        it 'enables soft takeover on input mappings', ->
            beh = behaviour.mapIn "[Test]", "test"
            beh.script = mock.testScript()

            option.softTakeover.enable beh
            expect(beh.script.mixxx.engine.softTakeover)
                .toHaveBeenCalledWith "[Test]", "test", true

            option.softTakeover.disable beh
            expect(beh.script.mixxx.engine.softTakeover)
                .toHaveBeenCalledWith "[Test]", "test", false

        it 'replaces dashes from option names', ->
            expect(option.invert.name).toBe 'invert'
            expect(option.softTakeover.name).toBe 'soft-takeover'


    describe 'Behaviour', ->

        behav = null
        beforeEach ->
            behav = mockBehaviour initial: 32

        it 'returns the same MIDI value as normal value', ->
            expect(behav.value).toBe behav.midiValue
            expect(behav.value).toBe 32

            behav.value = 64
            expect(behav.value).toBe behav.midiValue
            expect(behav.value).toBe 64

        it 'transforms MIDI input events with given options', ->
            behav.option transform: (x) -> x * 2
            actor = new behaviour.Actor
            behav.enable {}, actor

            actor.emit 'event', value: 3
            expect(behav.onMidiEvent).toHaveBeenCalledWith value: 6

            behav.option transform: (x) -> x - 1

            actor.emit 'event', value: 3
            expect(behav.onMidiEvent).toHaveBeenCalledWith value: 5

        it 'processes MIDI input events with given options', ->
            behav.option process: (ev, b) -> ev.value = ev.value * 2
            actor = new behaviour.Actor
            behav.enable {}, actor

            actor.emit 'event', value: 3
            expect(behav.onMidiEvent).toHaveBeenCalledWith value: 6

            behav.option process: (ev, b) -> ev.value = ev.value - b.midiValue
            actor.emit 'event', value: 3
            expect(behav.onMidiEvent).toHaveBeenCalledWith value: -26

        it 'transforms can use the previous value', ->
            opt = createSpyObj 'option', ['transform']
            behav.option opt

            actor = new behaviour.Actor
            behav.enable {}, actor

            actor.emit 'event', value: 3
            expect(opt.transform).toHaveBeenCalledWith 3, 32

        it 'options are enabled and disabled', ->
            opt = createSpyObj 'option', ['enable', 'disable']
            behav.option opt

            script = {}
            actor = new behaviour.Actor
            behav.enable script, actor
            expect(opt.enable).toHaveBeenCalledWith behav

            behav.disable script, actor
            expect(opt.disable).toHaveBeenCalledWith behav

        it 'can take options with an option chooser syntax', ->
            behav.options.spread64
            behav.options.softTakeover
            expect(behav._options).toEqual [
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
            expect(actor.doSend).toHaveBeenCalledWith 'on'

        it 'initializes the actor even if it denies output', ->
            actor.send = undefined
            output.output.value = 1
            output.enable {}, actor
            expect(actor.doSend).toHaveBeenCalledWith 'on'

        it 'sends "on" value when value is above or equal minimum', ->
            output.enable {}, actor
            output.output.value = 1
            expect(actor.send).toHaveBeenCalledWith 'on'

        it 'sends "on" value when value is bellow minimum', ->
            output.enable {}, actor
            output.output.value = 1
            output.output.value = 0
            expect(actor.send).toHaveBeenCalledWith 'off'


    describe 'Transform', ->

        it 'can take an initial value as second parameter', ->
            t = behaviour.transform (->), 42
            expect(t.value).toBe 42

        it 'sets its value and output to the transformed MIDI input', ->
            t = behaviour.transform (v) -> v * 2

            t.onMidiEvent value: 3
            expect(t.value).toBe 6
            expect(t.output.value).toBe 6
            expect(t.midiValue).toBe 6

            t.onMidiEvent value: 6
            expect(t.value).toBe 12
            expect(t.output.value).toBe 12
            expect(t.midiValue).toBe 12

        it 'can inverse the transform to reconstruct the midi values', ->
            f = (v) -> v * 2
            f.inverse = (v) -> v / 2
            t = behaviour.transform f

            t.onMidiEvent value: 3
            expect(t.value).toBe 6
            expect(t.midiValue).toBe 3

        it 'does not set its value when the transform gives a nully value', ->
            t = behaviour.transform (v) -> if v != 42 then v * 2

            t.onMidiEvent value: 3
            expect(t.value).toBe 6

            t.onMidiEvent value: 42
            expect(t.value).toBe 6

            t.onMidiEvent value: 0
            expect(t.value).toBe 0

        it 'can take non-linear transforms', ->
            t = behaviour.transform transform.binaryT

            t.onMidiEvent value: 3
            expect(t.value).toBe true

            t.onMidiEvent value: 3
            expect(t.value).toBe false


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
            script = mock.testScript()

        it 'returns the value as midi value when not inversible transform', ->
            expect(map.value).toBe map.midiValue
            expect(map.midiValue).toBe 42

            map.value = 32
            expect(map.value).toBe map.midiValue
            expect(map.midiValue).toBe 32

        it 'uses the inverse of the transform to produce back the MIDI values', ->
            map.transform inverse: (x) -> x - 10

            expect(map.value).toBe 42
            expect(map.midiValue).toBe 32

            map.value = 32
            expect(map.value).toBe 32
            expect(map.midiValue).toBe 22


    describe 'Map', ->

        map2   = null
        map    = null
        actor  = null
        script = null

        beforeEach ->
            map    = behaviour.map "[Test]", "test"
            map2   = behaviour.map "[Test]", "test", "[Test2]", "test2"
            actor  = mockActor()
            script = mock.testScript()

        it 'does not listen to the Mixxx control unnecesarily', ->
            actor.send = undefined
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .not.toHaveBeenCalled()

        it 'connects to the Mixxx control when actor has send', ->
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Test]", "test", script.handlerKey()

        it 'connects to output control when different from input', ->
            map2.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Test2]", "test2", script.handlerKey()

        it 'direct maps output to the right parameter', ->
            expect(map.directOutMapping()).toEqual {
                group: "[Test]",  key: "test", minimum: 1 }
            expect(map2.directOutMapping()).toEqual {
                 group: "[Test2]", key: "test2", minimum: 1 }

        it 'direct maps input to the right parameter', ->
            expect(map.directInMapping()).toEqual {
                group: "[Test]",  key: "test" }
            expect(map2.directInMapping()).toEqual {
                group: "[Test]",  key: "test" }

        it 'connects to the Mixxx control when someone is obsrving "value"', ->
            map.on "value", ->
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Test]", "test", script.handlerKey()

        it 'initializes the value and output with the current engine status', ->
            script.mixxx.engine.getValue = (group, key) ->
                if group == "[Test]" and key == "test"
                    1
                else if group == "[Test2]" and key == "test2"
                    2
                else
                    null
            map2.enable script, actor
            expect(map2.value).toBe(1)
            expect(map2.output.value).toBe(2)

        it 'sets the values in the engine using the default transform', ->
            xfader = behaviour.map "[Master]", "crossfader"
            xfader.enable script, actor

            xfader.onMidiEvent value: 63.5
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0.0

            xfader.onMidiEvent value: 127
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 1

            xfader.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 1

        it 'sets the values in the engine using custom transformation', ->
            xfader = behaviour.map("[Master]", "crossfader").transform (v) -> v
            xfader.enable script, actor

            xfader.onMidiEvent value: 64
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 64

            xfader.onMidiEvent value: 127
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 127

            xfader.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0

        it 'does not direct map output when a custom transform is set', ->
            xfader = behaviour.map("[Master]", "crossfader").transform (v) -> v
            expect(xfader.directInMapping()).toBe undefined

        it 'does not direct map input when a custom transform is set', ->
            xfader = behaviour.map("[Master]", "crossfader").meter (v) -> v
            expect(xfader.directOutMapping()).toBe undefined

        it 'does nothing when the transform return null', ->
            xfader = behaviour.map("[Master]", "crossfader").transform (v) ->
                if v == 64 then 64 else null
            xfader.enable script, actor

            xfader.onMidiEvent value: 32
            expect(script.mixxx.engine.setValue)
                .not.toHaveBeenCalled()

            xfader.onMidiEvent value: 64
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 64

        it 'does toggle from previous state when binary transform', ->
            lock = behaviour.map "[Channel1]", "keylock"
            lock.enable script, actor

            lock.onMidiEvent value: 32
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Channel1]", "keylock", true

            lock.onMidiEvent value: 32
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Channel1]", "keylock", false


    describe 'Chooser', ->
        actor   = null
        script  = null
        chooser = null
        engine  = null

        beforeEach ->
            chooser = behaviour.chooser()
            actor   = mockActor()
            script  = mock.testScript()
            engine  = script.mixxx.engine
            chooser.add "[Channel1]", "pfl"
            chooser.add "[Channel2]", "pfl"
            chooser.add "[Channel3]", "pfl"
            chooser.add "[Channel4]", "pfl"

        it "activates the right option, when chooser is enabled", ->
            chooser.enable script, actor

            chooser.activate 0
            expect(engine.getValue "[Channel1]", "pfl").toBe true
            expect(engine.getValue "[Channel2]", "pfl").toBe false

            chooser.activate 1
            expect(engine.getValue "[Channel1]", "pfl").toBe false
            expect(engine.getValue "[Channel2]", "pfl").toBe true

        it "activates the right option, when first activator is enabled", ->
            chooser.activator(0).enable script, actor
            chooser.activate 0
            expect(engine.getValue "[Channel1]", "pfl").toBe true
            expect(engine.getValue "[Channel2]", "pfl").toBe false

        it "activates the right option, when second activator is enabled", ->
            chooser.activator(1).enable script, actor
            chooser.activate 1
            expect(engine.getValue "[Channel1]", "pfl").toBe false
            expect(engine.getValue "[Channel2]", "pfl").toBe true

        it "activators activate when they receive non-zero value", ->
            chooser.activator(0).enable script, actor
            chooser.activator(1).enable script, actor

            chooser.activator(1).onMidiEvent value: 1
            expect(engine.getValue "[Channel1]", "pfl").toBe false
            expect(engine.getValue "[Channel2]", "pfl").toBe true

            chooser.activator(0).onMidiEvent value: 1
            expect(engine.getValue "[Channel1]", "pfl").toBe true
            expect(engine.getValue "[Channel2]", "pfl").toBe false

            chooser.activator(1).onMidiEvent value: 0
            expect(engine.getValue "[Channel1]", "pfl").toBe true
            expect(engine.getValue "[Channel2]", "pfl").toBe false

        it "toggles the selected option on or off", ->
            chooser.enable script, actor
            chooser.activate 1
            expect(engine.getValue "[Channel1]", "pfl").toBe false
            expect(engine.getValue "[Channel2]", "pfl").toBe true
            chooser._updateValue() # simulate callback

            chooser.onMidiEvent value: 1
            expect(engine.getValue "[Channel1]", "pfl").toBe false
            expect(engine.getValue "[Channel2]", "pfl").toBe false
            chooser._updateValue() # simulate callback

            chooser.onMidiEvent value: 1
            expect(engine.getValue "[Channel1]", "pfl").toBe false
            expect(engine.getValue "[Channel2]", "pfl").toBe true

        it "connects and disconnects from controls", ->
            chooser.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Channel1]", "pfl", jasmine.any(String)
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Channel2]", "pfl", jasmine.any(String)

            chooser.disable script, actor
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Channel1]", "pfl",
                    jasmine.any(String), true
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Channel2]", "pfl",
                    jasmine.any(String), true

        it "initialzies its value to true", ->
            engine.setValue "[Channel1]", "pfl", true
            chooser.enable script, actor
            expect(chooser.value).toBe true

        it "initialzies its value to false", ->
            chooser.enable script, actor
            expect(chooser.value).toBe false

        it "can select with a selector knob", ->
            selector = chooser.selector()
            chooser.enable script, actor
            selector.enable script, actor
            chooser.activate 0
            chooser._updateValue()

            selector.onMidiEvent value: 32
            expect(engine.getValue "[Channel1]", "pfl").toBe false
            expect(engine.getValue "[Channel2]", "pfl").toBe true
            expect(engine.getValue "[Channel3]", "pfl").toBe false
            expect(engine.getValue "[Channel4]", "pfl").toBe false

            selector.onMidiEvent value: 80
            expect(engine.getValue "[Channel1]", "pfl").toBe false
            expect(engine.getValue "[Channel2]", "pfl").toBe false
            expect(engine.getValue "[Channel3]", "pfl").toBe true
            expect(engine.getValue "[Channel4]", "pfl").toBe false

            selector.onMidiEvent value: 120
            expect(engine.getValue "[Channel1]", "pfl").toBe false
            expect(engine.getValue "[Channel2]", "pfl").toBe false
            expect(engine.getValue "[Channel3]", "pfl").toBe false
            expect(engine.getValue "[Channel4]", "pfl").toBe true

        it "selector value is transformed back to MIDI", ->
            selector = chooser.selector()
            chooser.enable script, actor
            selector.enable script, actor
            chooser.activate 0
            chooser._updateValue()

            chooser.select 0
            chooser._updateValue()
            expect(selector.midiValue).toBe 0

            chooser.select 1
            chooser._updateValue()
            expect(selector.midiValue).toBe 32

            chooser.select 2
            chooser._updateValue()
            expect(selector.midiValue).toBe 64

            chooser.select 3
            chooser._updateValue()
            expect(selector.midiValue).toBe 96

        it "selector value keeps MIDI offset", ->
            selector = chooser.selector()
            chooser.enable script, actor
            selector.enable script, actor
            chooser.activate 0
            chooser._updateValue()

            selector.onMidiEvent value: 36
            expect(selector.midiValue).toBe 36

            selector._updateValue 1
            expect(selector.midiValue).toBe 36

        it "can select before or after being enabled", ->
            chooser.select 2
            chooser.enable script, actor

            chooser.onMidiEvent value: 1
            expect(engine.getValue "[Channel1]", "pfl").toBe false
            expect(engine.getValue "[Channel2]", "pfl").toBe false
            expect(engine.getValue "[Channel3]", "pfl").toBe true
            expect(engine.getValue "[Channel4]", "pfl").toBe false

            chooser.select 1
            expect(engine.getValue "[Channel1]", "pfl").toBe false
            expect(engine.getValue "[Channel2]", "pfl").toBe true
            expect(engine.getValue "[Channel3]", "pfl").toBe false
            expect(engine.getValue "[Channel4]", "pfl").toBe false

        it "assumes engine keeps exclusivity with auto-exclusive", ->
            chooser = behaviour.chooser autoExclusive: true
            chooser.add "[Channel1]", "pfl"
            chooser.add "[Channel2]", "pfl"
            chooser.enable script, actor

            chooser.activate 1
            expect(engine.getValue "[Channel1]", "pfl").toBe 0
            expect(engine.getValue "[Channel2]", "pfl").toBe true

            chooser.activate 0
            expect(engine.getValue "[Channel1]", "pfl").toBe true
            expect(engine.getValue "[Channel2]", "pfl").toBe true

        it "calls onDisable to materialize disabling", ->
            spy = createSpyObj "disabler", ['onDisable']
            chooser = behaviour.chooser onDisable: spy.onDisable
            chooser.add "[Channel1]", "pfl"
            chooser.add "[Channel2]", "pfl"
            chooser.enable script, actor

            chooser.onMidiEvent value: 1
            expect(spy.onDisable).not.toHaveBeenCalled()

            chooser.value = true
            chooser.onMidiEvent value: 1
            expect(spy.onDisable).toHaveBeenCalled()

        it "reads value from optional second key", ->
            spy = createSpyObj "disabler", ['onDisable']
            chooser = behaviour.chooser()
            chooser.add "[Channel1]", "pfl", "listen"
            chooser.add "[Channel2]", "pfl", "listen"
            chooser.enable script, actor

            expect(script.mixxx.engine.connectControl)
                .not.toHaveBeenCalledWith "[Channel1]", "pfl", jasmine.any(String)
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Channel1]", "listen", jasmine.any(String)

            engine.setValue "[Channel1]", "pfl", true
            chooser._updateValue()
            expect(chooser.value).toBe false

            engine.setValue "[Channel1]", "pfl", false
            engine.setValue "[Channel1]", "listen", true
            chooser._updateValue()
            expect(chooser.value).toBe true


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
            script    = mock.testScript()
            when_     = behaviour.when condition, wrapped

        it "does nothing when enabled and condition not satisifed", ->
            when_.enable script, actor
            expect(wrapped.enable).
                not.toHaveBeenCalled()

        it "enables wrapped when condition is satisfied", ->
            condition.value = true
            when_.enable script, actor
            expect(wrapped.enable).
                toHaveBeenCalledWith script, actor

        it "disables wrapped when it is disabled", ->
            condition.value = true
            when_.enable script, actor
            when_.disable script, actor
            expect(wrapped.disable).
                toHaveBeenCalledWith script, actor

        it "enables or disables wrapped when condition changes", ->
            when_.enable script, actor
            condition.value = true
            expect(wrapped.enable).
                toHaveBeenCalledWith script, actor
            condition.value = false
            expect(wrapped.disable).
                toHaveBeenCalledWith script, actor

        it "generates a new negated version on 'else", ->
            wrapped2 = mockBehaviour()
            else_ = when_.else wrapped2
            condition.value = true
            else_.enable script, actor
            expect(wrapped2.enable).
                not.toHaveBeenCalledWith script, actor
            condition.value = false
            expect(wrapped2.enable).
                toHaveBeenCalledWith script, actor

        it "else-when chains enable one branch exclusively", ->
            condition2 = value.value false
            wrapped2 = mockBehaviour()
            elseWhen_ = when_.else.when condition2, wrapped2

            wrapped3 = mockBehaviour()
            else_ = when_.else wrapped3

            when_.enable script, actor
            elseWhen_.enable script, actor
            else_.enable script, actor

            expect(wrapped.actor).not.toBeDefined()
            expect(wrapped2.actor).not.toBeDefined()
            expect(wrapped3.actor).toBeDefined()

            condition.value = true
            expect(wrapped.actor).toBeDefined()
            expect(wrapped2.actor).not.toBeDefined()
            expect(wrapped3.actor).not.toBeDefined()

            condition2.value = true
            expect(wrapped.actor).toBeDefined()
            expect(wrapped2.actor).not.toBeDefined()
            expect(wrapped3.actor).not.toBeDefined()

            condition.value = false
            expect(wrapped.actor).not.toBeDefined()
            expect(wrapped2.actor).toBeDefined()
            expect(wrapped3.actor).not.toBeDefined()

            condition2.value = false
            expect(wrapped.actor).not.toBeDefined()
            expect(wrapped2.actor).not.toBeDefined()
            expect(wrapped3.actor).toBeDefined()

        it "exposes wether it meets the condition on its 'value'", ->
            when_.enable script, actor
            condition.value = true
            expect(when_.value).toBe true
            condition.value = false
            expect(when_.value).toBe false

        it "propagates options to the wrapped behaviour", ->
            when_.option behaviour.option.softTakeover
            expect(wrapped._options).toEqual [
                behaviour.option.softTakeover
            ]

            when_.option behaviour.option.invert
            expect(wrapped._options).toEqual [
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
            script       = mock.testScript()
            script.mixxx.engine.getValue = (group, control) ->
                expect(group).toBe "[Master]"
                expect(control).toBe "crossfader"
                xfader
            leftPunchIn.enable script, actor
            rightPunchIn.enable script, actor

        it "does nothing when the crossfader is to the requested side", ->
            xfader = -0.75
            leftPunchIn.onMidiEvent value: 1
            expect(script.mixxx.engine.setValue).not.toHaveBeenCalled()
            leftPunchIn.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue).not.toHaveBeenCalled()

            xfader = 0.75
            rightPunchIn.onMidiEvent value: 1
            expect(script.mixxx.engine.setValue).not.toHaveBeenCalled()
            rightPunchIn.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue).not.toHaveBeenCalled()

        it "sets the crossfader to the middle and restores otherwise", ->
            xfader = 0.75
            leftPunchIn.onMidiEvent value: 1
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0.0
            leftPunchIn.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0.75

            xfader = -0.75
            rightPunchIn.onMidiEvent value: 1
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", 0.0
            rightPunchIn.onMidiEvent value: 0
            expect(script.mixxx.engine.setValue)
                .toHaveBeenCalledWith "[Master]", "crossfader", -0.75


    describe 'scratchEnable', ->

        actor   = null
        script  = null
        scratch = null

        beforeEach ->
            actor   = mockActor()
            script  = mock.testScript()
            scratch = behaviour.scratchEnable 1, 32, 33, 1, 0.4, false
            scratch.enable script, actor

        it 'enables scratch on button press', ->
            expect(script.mixxx.engine.scratchEnable)
                .not.toHaveBeenCalled()

            scratch.onMidiEvent value: 1
            expect(script.mixxx.engine.scratchEnable)
                .toHaveBeenCalledWith 1, 32, 33, 1, 0.4, false

        it 'disables scratch on button release', ->
            expect(script.mixxx.engine.scratchDisable)
                .not.toHaveBeenCalled()

            scratch.onMidiEvent value: 0
            expect(script.mixxx.engine.scratchEnable)
                .not.toHaveBeenCalled()
            expect(script.mixxx.engine.scratchDisable)
                .toHaveBeenCalledWith 1, false


    describe 'scratchTick', ->

        actor   = null
        script  = null
        scratch = null

        beforeEach ->
            actor   = mockActor()
            script  = mock.testScript()
            scratch = behaviour.scratchTick 1, (v) -> v / 2
            scratch.enable script, actor

        it 'ticks the given deck scratch with the current transform', ->
            expect(script.mixxx.engine.scratchTick)
                .not.toHaveBeenCalled()

            scratch.onMidiEvent value: 64
            expect(script.mixxx.engine.scratchTick)
                .toHaveBeenCalledWith 1, 32

            scratch.onMidiEvent value: 32
            expect(script.mixxx.engine.scratchTick)
                .toHaveBeenCalledWith 1, 16

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
