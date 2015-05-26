mixco.behaviour
===============

This module contains all the functionallity that lets you add
*behaviour* to the hardware *controls* -- i.e. determine what they do.

    events    = require 'events'
    transform = require './transform'
    value     = require './value'
    {indent, assert, factory, copy} = require './util'
    {multi, isinstance} = require 'heterarchy'
    _ = {extend, bind, map} = require 'underscore'

Actor
-----

An **Actor** is the basic object that we want to add behaviours to.
In general, they are *controls*, as defined by the `mixco.control`
module.  They have an `event` event, however, it is not guaranteed to
be emitted if the interface decides that direct mappings suffice.

`send` should be defined with signature `(state) ->` when it is
available -- i.e. the *Actor* has output and requires the associated
behaviours to update it.

    class exports.Actor extends events.EventEmitter

        send: undefined

Options
-------

These modify a behaviour in the same way that the equivalent options
for the `<option>` section of the Mixxx control mapping section do.
These can be used either at *control* or *behaviour* level.  An option
has the following interface:

- A `name` with the name of the option in the XML file.
- Optionally, a `transform` function that maps the value and
  the previous received value to a transformed one.
- Optionally, a `enable` and `disable` functions that take a behaviour
  that they may affect.
- Optionally, a `process` function that takes a MIDI event and a
  behaviour and can manipulate the MIDI event.

This `option` object contains all the available options in Mixxx, with
names converted to idiomatic JavaScript -- e.g. *soft-takeover* becomes
*softTakeover*.

These impementations are simplifications of what there is in
`MidiController::computeValue` in Mixxx.  Please check them from time
to time.  Also the way we implement non-linear transforms is
inconsistent with how Mixxx does it, but it should be though.

    toOption = (option) ->
        result = option
        if isinstance option, Function
            result = transform: option
        if result.transform? and not result.process?
            result.process =
                if result.transform.length == 1
                    (ev, b) -> ev.value = @transform ev.value
                else
                    (ev, b) -> ev.value = @transform ev.value, b.midiValue
        result

    option = exports.option = do ->
        result = {}
        add    = (names..., option) ->
            [mixxxName, name] = names
            desc = toOption option
            desc.name = mixxxName
            result[name ? mixxxName] = desc
            result

        rot64   = (sign) -> (v1, v0) ->
            diff = v1 - 64.
            diff =
                if diff == -1 or diff == 1
                then diff / 16.0
                else diff - diff.sign()
            (v0 + diff * sign).clamp 0, 127

        add 'invert', (v) -> 127.0 - v
        add 'rot64', rot64 1
        add 'rot64inv', rot64 -1
        add 'rot64fast', (v1, v0) -> (v0 + (v1 - 64) * 1.5).clamp 0, 127
        add 'diff', (v1, v0) -> v0 + (if v1 > 64 then v1 - 128 else v1)
        add 'button', (v) -> v != 0
        add 'switch', (v) -> 1
        result.switch_ = result.switch
        add 'hercjog', (v1, v0) -> v0 + (if v1 > 64 then v1 - 128 else v1)
        add 'spread64', (v) -> v - 64
        add 'selectknob', (v) -> if v > 64 then v - 128 else v
        add 'soft-takeover', 'softTakeover',
            enable:  (b) ->
                if isinstance b, exports.MapIn
                    b.script.mixxx.engine.softTakeover \
                        b.group, b.key, true
            disable: (b) ->
                if isinstance b, exports.MapIn
                    b.script.mixxx.engine.softTakeover \
                        b.group, b.key, false

The *makeOptionsChooser* object is used to implement easy adding of
options by just accessing a nested attribute of an object.  For
example, in a behaviour `b`, accessing `b.options.spread64`
automatically enables that option and returns `b`.

    exports.makeOptionsChooser = makeOptionsChooser = (obj) ->
        result = {}
        for key, opt of option
            Object.defineProperty result, key, get: do (opt) ->
                -> obj.option opt
        result

Behaviours
----------

A **Behaviour** determines how a control should behave under some
circunstances. In general, behaviours are values also, so one can
listen to them.

    class exports.Behaviour extends value.Value

Behaviours can be enabled or disabled, to activate the behaviour of a
given actor.

        enable: (script, actor) ->
            assert not @actor?
            assert not @script?
            @script = script
            @actor = actor

            @_eventListener = (ev) =>
                if @_options?
                    ev = copy ev
                    for opt in @_options
                        opt.process?(ev, @)
                @onMidiEvent ev
            actor.on 'event', @_eventListener

            if @_options?
                for opt in @_options
                    opt.enable?(@)

        disable: (script, actor) ->
            assert @script == script
            assert @actor == actor
            if @_options?
                for opt in @_options
                    opt.disable?(@)
            actor.removeListener 'event', @_eventListener
            delete @script
            delete @actor

Adds an *option* to the behaviour, as seen above.  An *option chooser*
syntax is also available.

        option: (options...) ->
            for opt in options
                assert opt
            (@_options ?= []).push map(options, toOption)...
            this

        @property 'options', -> makeOptionsChooser @

Add an *options* option chooser for easier syntax.

Define a **directMapping** when the Behaviour can be mapped directly
to a Mixxx actor. Note that this should not depend on conditions
determined after the XML configuration is generated.

        directInMapping: -> null
        directOutMapping: -> null

Interface to receive MIDI and map the current value from MIDI.

        onMidiEvent: (ev) -> null
        getMidiValue: -> @value
        @property 'midiValue', -> @getMidiValue()

### Call

The simplest behaviour just calls a function when it receives
something.

    class exports.Call extends exports.Behaviour

        constructor: (@onMidiEvent) ->
            super()

    exports.call = factory exports.Call


### Output

Adds some common operations for behaviours that can update the
output of its actor based on its nested `output` *Value*.

    class exports.Output extends exports.Behaviour

        minimum: 1
        maximum: undefined

        constructor: ->
            super
            @output = value.value()

        enable: ->
            super
            if @actor.send?
                @_updateOutputCallback ?= => @updateOutput()
                @output.on 'value', @_updateOutputCallback
            if @actor.doSend?
                @updateOutput @actor.doSend

        disable: ->
            if @_updateOutputCallback?
                @removeListener 'value', @_updateOutputCallback
                @_updateOutputCallback = undefined
            super

        updateOutput: (sendfn=null) ->
            sendfn ?= @actor.send
            sendfn.call @actor, (if Math.abs(@output.value) >= @minimum \
                then 'on' else 'off')


### Transform

Simple behaviour that just transforms the input values into a value.
It takes one of the transforms of the `mixco.transform` module to map
the value.  It can take an *initial* value too.

    class exports.Transform extends exports.Output

        constructor: (@transformer, initial=undefined) ->
            super initial: initial

        onMidiEvent: (ev) ->
            result = @transformer ev.value, @midiValue
            if result?
                @output.value = @value = result

        getMidiValue: ->
            @transformer.inverse?(@value) ? @value

    exports.transform = factory exports.Transform
    exports.modifier  = -> exports.transform transform.momentaryT, false
    exports.switch    = -> exports.transform transform.binaryT, false
    exports.switch_   = exports.switch

### Mappings

#### Input

The **MapIn** behaviour maps the received input to a control in Mixxx.

    class exports.MapIn extends exports.Behaviour

        constructor: (ingroupOrParams, inkey=undefined) ->
            super
            {@group, @key} =
                if not isinstance ingroupOrParams, String
                then ingroupOrParams
                else
                    group: ingroupOrParams
                    key:   inkey
            @_transform = transform.mappings[@key]

        transform: (trans) ->
            @_transform = trans
            this

        enable: (script, actor) ->
            super

It seems that Mixxx does not update the direct-mapped outputs upon
initialization, so we have to update them manually unconditionally.

            engine = script.mixxx.engine
            @value = engine.getValue @group, @key

Then, if the value of the mapped control is observed from the script
we register a handler
to listen to it.

            if @listeners('value').length > 0
                @_inHandler ?= script.registerHandler (v) =>
                    @value = v
                engine.connectControl @group, @key, @_inHandler
                @_inHandlerConnected = true

        disable:  ->
            if @_inHandlerConnected?
                @script.mixxx.engine.connectControl \
                    @group, @key, @_inHandler, true
                @_inHandlerConnected = false
            super

        directInMapping: ->
            if @_transform == transform.mappings[@key]
                group: @group
                key:   @key

While in general mappings are done directly, bypassing the script,
under some circunstances it might happen that they are proccessed in
the script.  In this case, we define `onMidiEvent` to emulate the
behaviour of a direct mapping.

        onMidiEvent: (ev) ->
            val = @_transform ev.value, @midiValue
            if val?
                @script.mixxx.engine.setValue @group, @key, val
                if @listeners('value').length == 0
                    @value = val

        getMidiValue: ->
            @_transform?.inverse?(@value) ? @value

    exports.mapIn = factory exports.MapIn


#### Output

The **MapOut** behaviour maps the state of a control in Mixxx as
output to the controller.

    class exports.MapOut extends exports.Output

        constructor: (outgroupOrParams, outkey=undefined) ->
            super
            {@outgroup, @outkey} =
                if not isinstance outgroupOrParams, String
                then outgroupOrParams
                else
                    outgroup: outgroupOrParams
                    outkey:   outkey

        meter: (transformer = undefined) ->
            @_outTransform  = transformer
            @_outTransform ?= transform.mappings[@outkey].inverse
            @updateOutput = ->
                @actor.send Math.floor @_outTransform @output.value
            this

        enable: (script, actor) ->
            super

It seems that Mixxx does not update the direct-mapped outputs upon
initialization, so we have to update them manually unconditionally.

            engine = script.mixxx.engine
            @output.value = engine.getValue @outgroup, @outkey

If we need to manually send output to the actor, lets connect a
handler to it.

            if @output.listeners('value').length > 0
                @_outHandler ?= script.registerHandler (v) =>
                    @output.value = v
                engine.connectControl @outgroup, @outkey, @_outHandler
                @_outHandlerConnected = true

        disable:  ->
            if @_outHandlerConnected?
                @script.mixxx.engine.connectControl \
                    @outgroup, @outkey, @_outHandler, true
                @_outHandlerConnected = false
            super

        directOutMapping: ->
            if not @_outTransform?
                group:   @outgroup
                key:     @outkey
                minimum: @minimum

    exports.mapOut = factory exports.MapOut


#### Combinatios

The **map** behaviour is the most common one.  It maps both input and
output to a control in Mixxx.

    class exports.Map extends multi exports.MapIn, exports.MapOut

        constructor: (groupOrParams, key, outgroup, outkey) ->
            params =
                if not isinstance groupOrParams, String
                then groupOrParams
                else
                    group:    groupOrParams
                    key:      key
                    outgroup: outgroup,
                    outkey:   outkey
            params.outgroup ?= params.group
            params.outkey   ?= params.key
            super params

    exports.map = factory exports.Map


The **toBehaviour** factory builds a default behaviour from a set
of arguments.  If the argument is just a behaviour, it returns it.

    exports.toBehaviour = (behaviour, args...) ->
        if args.length > 0
            exports.map behaviour, args...
        else
            behaviour

The **soft** behaviour is a mapping with the `softTakeover` option
enabled.

    exports.soft = ->
        exports.map(arguments...).option(option.softTakeover)

The *set* behaviour sets a control to a spefic value whenever it is
pressed.  The *toggle* behaviour instead sets it to two different
value on press or release.

    exports.toggle = (offValue, onValue, args...) ->
        exports.map(args...).transform (val) ->
            if val then onValue else offValue

    exports.set = (valueToSet, args...) ->
        exports.toggle valueToSet, null, args...


### Chooser

The **Chooser** can select in a exclusive way one of a series of
boolean toggles. One clear use-case is selecting the pre-hear `pfl`
track, such that only one track has pre-hear enabled at a time.

There are two ways of using it:

 * With **activators**.  Each activator is a boolean behaviour that
   turns on the option of a given index.

 * With the **selector**.  The selector maps a continuous control to one
   of the options.  The the chooser itself can be used to turn the
   selected option on/off.

    class exports.Chooser extends exports.Output

        constructor: ({@autoExclusive, @onDisable} = {})->
            super
            @_selectedIndex    = null
            @_chooseOptions    = []
            @_chooseActivators = []
            @_chooseSelectors  = []
            @_chooseHandles    = []

The **add** method adds an option and returns the activator for
it. The parameter *listen* is a second optional key that is used for
retreiving the value as opposed to setting it.

        add: (group, key, listen=null) ->
            idx       = @_chooseOptions.length
            activator = exports.map(group, key)
                .transform (val) =>
                    if val > 0 then @activate idx
                    null
            @_chooseOptions.push [group, key, listen]
            @_chooseActivators.push activator
            activator

        enable: (script) ->
            super
            @_updateValueHandler ?= script.registerHandler =>
                @_updateValue()
            engine = script.mixxx.engine
            for [group, key, listen] in @_chooseOptions
                listen ?= key
                engine.connectControl group, listen, @_updateValueHandler
            @_updateValue()

        disable: (script) ->
            assert @_updateValueHandler
            engine = script.mixxx.engine
            for [group, key, listen] in @_chooseOptions
                listen ?= key
                engine.connectControl group, listen, @_updateValueHandler, true
            super

        activator: (idx) ->
            assert 0 <= idx < @_chooseOptions.length
            @_chooseActivators[idx]

The **selector** can be used to select to control selection with a
knob.  It keeps the fractional part of the computed index in its
`value`, thus allowing usage with relative encoders.

        selector: ->
            select = (v) =>
                v = (v / 128.0 * @_chooseOptions.length)
                    .clamp 0, @_chooseOptions.length-1
                @_update index: Math.floor v
                v
            select.inverse = (v) => v / @_chooseOptions.length * 128.0

            selector = extend exports.transform(select),
                _updateValue: (newv) ->
                    if Math.floor(newv) != Math.floor(@value)
                        @value = @output.value = newv

            @_chooseSelectors.push selector
            selector

The **momentary** behaviour will toggle the chooser while the button
is pressed, not otherwise.

        momentary: ->
            exports.action
                press:   => @_update enable: true
                release: => @_update enable: false

        activate: (idx) ->
            @_update
                index:  idx
                enable: true
            @

        select: (idx) ->
            if @actor?
                @_update
                    index:  idx
                    enable: true
            else
                @_selectedIndex = idx
            @

        onMidiEvent: (event) ->
            if event.value
                enable = not @value
                @_update enable: enable
                if not enable
                    @onDisable?()

        _update: ({index, enable}={}) ->
            enable ?= @value
            index  ?= @_selectedIndex
            index   = index?.clamp 0, @_chooseOptions.length-1

            if index != @_selectedIndex or enable != @value
                script  = @script ? @_chooseActivators[index].script
                if index?
                    [group, key, listen] = @_chooseOptions[index]
                    script.mixxx.engine.setValue group, key, enable
                if not @autoExclusive or not enable
                    for [group, key], idx in @_chooseOptions
                        if idx != index
                            script.mixxx.engine.setValue group, key, false
                @_selectedIndex = index

        _updateValue:->
            if @script?
                engine = @script.mixxx.engine
                @value = @output.value =
                    _.some @_chooseOptions, ([group, key, listen]) ->
                        listen ?= key
                        engine.getValue group, listen
                for selector in @_chooseSelectors
                    selector._updateValue @_selectedIndex
            @
    exports.chooser = factory exports.Chooser


### Conditionals

Conditional behaviours are used to enable a *wrapped* behaviour only
under certain circumstances -- i.e. when some `behaviour.Value`
evaluates to true.  They are used to implement the `when` and `else`
methods of the `control.Control` class.

    class exports.When extends exports.Behaviour

        constructor: (@_condition, wrapped...) ->
            @else      = => @_else arguments...
            @else.when = => @_elseWhen arguments...
            @when      = @else.when
            @else_     = @else

            super()
            @_wrapped = exports.toBehaviour wrapped...
            @_condition.on 'value', => @_update()
            if @_lastCondition  != 'no-more-negations'
                @_lastCondition = @_condition
                @_lastCondition.negation ?= value.not @_condition

        option: ->
            super
            @_wrapped.option arguments...
            this

        _elseWhen: (condition, args...) ->
            assert @_lastCondition?, "Can not define more conditions after 'else'"
            nextCondition =
                value.and condition, value.not @_lastCondition
            nextCondition.negation =
                value.and @_lastCondition.negation, value.not condition
            @_lastCondition = nextCondition
            new exports.When nextCondition, args...

        _else: (args...) ->
            assert @_lastCondition?, "Can not define more conditions after 'else'"
            nextCondition = @_lastCondition.negation
            nextCondition.negation = 'no-more-negations'
            delete @_lastCondition
            new exports.When nextCondition, args...

        enable: (args...) ->
            super
            @_enableOn = args
            @_enableRequested = true
            @_update()

        disable: ->
            @_enableRequested = false
            @_update()
            super

        _update: ->
            @value = @_enableRequested and @_condition.value
            if @_wrapped.actor and not @value
                @_wrapped.disable @_enableOn...
            if not @_wrapped.actor and @value
                @_wrapped.enable @_enableOn...


Conditional behaviours can not be directly mapped, as they have to
determine, in the script, wether they are enabled or not.

        directOutMapping: -> null
        directInMapping: -> null

    exports.when = factory exports.When


### Special actions

An the *action* helper behaviour is very useful when writing
script-only button actions with a press and a release event.

    class exports.Action extends exports.Output

        minimum: true

        constructor: (@action = undefined) ->
            super()
            @onPress   ?= @action.press
            @onRelease ?= @action.release

        onMidiEvent: (ev) ->
            val = @value = @output.value = ev.value > 0
            if val
                @onPress?()
            else
                @onRelease?()

    exports.action = factory exports.Action


**PunchIn** tries to mimic the punch-in functionaility of a mixer by
setting the crossfader to the center.  The threshold must be either
positive or negative for the left channel and indicates how far the
crossfader has to be from the center for punch-in to have effect.
Note that this does not work properly when soft takeover is enabled on
the crossfader.

    exports.punchIn = (threshold, threshold2=undefined) ->
        oldxfader   = undefined
        inThreshold = (newxfader, threshold) ->
            (threshold < 0 and newxfader < threshold) or
            (threshold > 0 and newxfader > threshold)

        exports.action
            press: ->
                engine    = @script.mixxx.engine
                newxfader = engine.getValue "[Master]", "crossfader"
                if inThreshold(newxfader, threshold) or
                        (threshold2? and inThreshold(newxfader, threshold2))
                    oldxfader = newxfader
                    engine.setValue "[Master]", "crossfader", 0

            release: ->
                engine = @script.mixxx.engine
                if oldxfader?
                    engine.setValue "[Master]", "crossfader", oldxfader
                    oldxfader = undefined


The **scratchEnable** and **scratchTick** behaviour map to the
engine scratch system.

    exports.scratchEnable = (deck,
                             intervalsPerRev = 128*4,
                             rpm             = 44.0,
                             alpha           = 1.0 / 8.0,
                             beta            = 1.0 / 8.0 / 32.0,
                             ramp            = true) ->
        exports.action
            press: ->
                enable = @script.mixxx.engine.scratchEnable
                enable deck, intervalsPerRev, rpm, alpha, beta, ramp
            release: ->
                @script.mixxx.engine.scratchDisable deck, ramp

    exports.scratchTick = (deck, transform = (x) -> x) ->
        exports.call (ev) ->
            engine = @script.mixxx.engine
            engine.scratchTick deck, transform ev.value


The **beatJump** tries to jump forward or backwards by a number of
beats. Note that because of limitations in the engine it can get your
tracks out of sync, specially while they play.

    exports.beatJump = (group, delta) -> exports.action press: ->
        engine    = @script.mixxx.engine
        bpm       = engine.getValue group, "bpm"
        duration  = engine.getValue group, "duration"
        position  = engine.getValue group, "playposition"
        rate      = engine.getValue group, "rate"
        rateRange = engine.getValue group, "rateRange"
        rate      = 1 + rate * rateRange
        targetpos = position + 59.9 * rate / delta / bpm / duration
        play      = engine.getValue group, "play"
        if play
            latency    = engine.getValue "[Master]", "latency"
            targetpos += latency / 1000.0 / duration
        engine.setValue group, "playposition", targetpos.clamp 0, 1

The **spinback** and **brake** functionalities just call the
equivalent methods in the engine.

    exports.spinback = (deck, args...) ->
        exports.modifier().on 'value', ->
            @script.mixxx.engine.spinback deck, @value, args...

    exports.brake = (deck, args...) ->
        exports.modifier().on 'value', ->
            @script.mixxx.engine.brake deck, @value, args...

The **playhead** sends the current position meter a MIDI value and
blinks faster and faster as the play position aproaches the end of the
track.

    exports.playhead = (g) ->
        exports.mapOut(g, "playposition").meter do ->
            step = 0
            (pos) ->
                engine = @script.mixxx.engine
                duration = switch
                    when not engine.getValue g, "play" then undefined
                    when pos > .9  then 5
                    when pos > .8  then 9
                    when pos > .75 then 13
                    else undefined
                if duration?
                    step = (step + 1) % duration
                    if step > duration / 2 then 0 else pos * 127
                else
                    step = 0
                    pos * 127

The **beatEffect** is creates a *chooser* of that can be used for beat
loops or rolls.  The `channel` parameter is the usual deck name, the
`type` parameter can be set to `"roll"` to enable rolling.

    exports.beatEffect = (channel, type='') ->
        sizes = [ "0.0625", "0.125", "0.25", "0.5", "1",
                  "2", "4", "8", "16", "32", "64" ]
        result = exports.chooser
            autoExclusive: true
            onDisable: ->
                engine = @script.mixxx.engine
                if type != 'roll' and engine.getValue channel, "loop_enabled"
                    engine.setValue channel, "reloop_exit", true
        for size in sizes
            result.add channel,
                       "beatloop#{type}_#{size}_activate",
                       "beatloop_#{size}_enabled"
        result.select 4

The **stutter** does a stutter effect --i.e. quickly turns volume up
and down-- while pressed.

Note that *soft takeover must be disabled* for the pregain parameter
for this effect to work because it works ticking periodically and
turning the gain up and down.

    exports.stutter = (group, beats=0.25) ->
        tick = ->
            engine  = @script.mixxx.engine
            gain    = engine.getValue group, "pregain"
            newgain =
                if gain > 0
                    @_oldgain = gain; 0
                else
                    @_oldgain
            engine.setValue group, "pregain", newgain

        exports.action
            press: ->
                engine         = @script.mixxx.engine
                bpm            = engine.getValue group, "bpm"
                delta          = beats * 60000 / bpm
                @_timerHandle ?= @script.registerHandler bind tick, @
                @_timerId     ?= engine.beginTimer delta, @_timerHandle

            release: ->
                engine = @script.mixxx.engine
                engine.stopTimer @_timerId
                engine.setValue group, "pregain", @_oldgain if @_oldgain?
                delete @_timerId
                delete @_oldgain

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
