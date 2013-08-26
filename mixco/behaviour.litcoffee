mixco.behaviour
===============

This module contains all the functionallity that lets you add
*behaviour* to the hardware *controls* -- i.e. determine what they do.

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


Dependencies
------------

    events    = require 'events'
    transform = require './transform'
    util      = require './util'
    value     = require './value'

    indent  = util.indent
    assert  = util.assert
    factory = util.factory

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


Behaviours
----------

A **Behaviour** determines how a control should behave under some
circunstances. In general, behaviours are values also, so one can
listen to them.

    class exports.Behaviour extends value.Value

Behaviours can be enabled or disabled, to determine the behaviour of a
given actor.

        enable: (script, actor) ->
            assert not @actor?
            assert not @script?
            @script = script
            @actor = actor
            @_eventListener = (ev) => @onEvent ev
            actor.on 'event', @_eventListener

        disable: (script, actor) ->
            assert @script == script
            assert @actor == actor
            actor.removeListener 'event', @_eventListener
            delete @script
            delete @actor

Define a **directMapping** when the Behaviour can be mapped directly
to a Mixxx actor. Note that this should not depend on conditions
determined after the XML configuration is generated.

        directInMapping: -> null
        directOutMapping: -> null

        configOutput: (depth) ->

        onEvent: (ev) -> null

### Call

The simplest behaviour just calls a function when it receives
something.

    class exports.Call extends exports.Behaviour

        constructor: (@onEvent) ->

    exports.call = factory exports.Call


### Output

Adds some common operations for behaviours that can update the
output of its actor based on its nested `output` *Value*.

    class exports.Output extends exports.Behaviour

        minimum: 1

        constructor: ->
            super
            @output = do value.value

        enable: ->
            super
            if @actor?.send?
                @_updateOutputCallback or= => do @updateOutput
                @output.on 'value', @_updateOutputCallback
                do @updateOutput

        disable: ->
            if @_updateOutputCallback?
                @removeListener 'value', @_updateOutputCallback
                @_updateOutputCallback = undefined
            super

        updateOutput: ->
            @actor.send if Math.abs(@output.value) >= @minimum \
                then 'on' else 'off'


### Transform

Simple behaviour that just transforms the input values into a value.
It takes one of the transforms of the `mixco.transform` module to map
the value.  It can take an *initial* value too.

    class exports.Transform extends exports.Output

        constructor: (@transformer, initial=undefined) ->
            super initial

        onEvent: (ev) ->
            @output.value = @value = @transformer ev.value

    exports.transform = factory exports.Transform
    exports.modifier  = -> exports.transform transform.binaryT, false
    exports.option    = -> exports.transform (-> not @value), false


### Map

The **map** behaviour maps the hardware control directly to a control
in Mixxx. Note that its `value` property is guaranteed to be
synchronised with Mixxx only there are listeners on it.

    class exports.Map extends exports.Output

        constructor: (@group, @key, @outgroup, @outkey) ->
            super
            @outgroup or= @group
            @outkey or= @key
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
            @output.value = engine.getValue @outgroup, @outkey

Then, if the value of the mapped control is observed from the script
or we need to manually send output to the actor, we register a handler
to listen to it.

            if @listeners('value').length > 0
                @_inHandler or= script.registerHandler (v) =>
                    @value = v
                engine.connectControl @group, @key, @_inHandler
                @_inHandlerConnected = true

            if @output.listeners('value').length > 0
                @_outHandler or= script.registerHandler (v) =>
                    @output.value = v
                engine.connectControl @outgroup, @outkey, @_outHandler
                @_outHandlerConnected = true

        disable:  ->
            if @_inHandlerConnected?
                @script.mixxx.engine.connectControl @group, @key, @_inHandler, true
                @_inHandlerConnected = false
            if @_outHandlerConnected?
                @script.mixxx.engine.connectControl @outgroup, @outkey, @_outHandler, true
                @_outHandlerConnected = false
            super

        directInMapping: ->
            if @_transform == transform.mappings[@key]
                group: @group
                key:   @key
            else
                null

        directOutMapping: ->
            group: @outgroup
            key:   @outkey

While in general mappings are done directly, bypassing the script,
under some circunstances it might happen that they are proccessed in
the script.  In this case, we define `onEvent` to emulate the
behaviour of a direct mapping.

        onEvent: (ev) ->
            val = @_transform ev.value
            if val != null
                @script.mixxx.engine.setValue @group, @key, val

        configOutput: (depth) ->
            "#{indent depth}<minimum>#{@minimum}</minimum>"


    exports.map = factory exports.Map


The **toBehaviour** factory builds a default behaviour from a set
of arguments.  If the argument is just a behaviour, it returns it.

    exports.toBehaviour = (behaviour, args...) ->
        if args.length > 0
            exports.map behaviour, args...
        else
            behaviour


The **Soft** behaviour defines a mapping with soft takeover enabled.

    class exports.Soft extends exports.Map

        enable: ->
            super
            @script.mixxx.engine.softTakeover @group, @key, true

        disable: ->
            @script.mixxx.engine.softTakeover @group, @key, false
            super

When soft takeover is enabled we have to process the events through
the script.

        directInMapping: -> null

    exports.soft = factory exports.Soft


The *set* behaviour sets a control to a spefic value whenever it is
pressed.  The *toggle* behaviour instead sets it to two different
value on press or release.

    exports.toggle = (offValue, onValue, args...) ->
        exports.map(args...).transform (val) ->
            if val then onValue else offValue

    exports.set = (valueToSet, args...) ->
        exports.toggle valueToSet, null, args...


### Chooser

The **Chooser** lets you select a toggle control of the groups
(e.g. decks), such that is enabled only one at a time.  One clear
use-case is selecting the pre-hear `pfl` track, such that only one
track has pre-hear enabled at a time.

    class exports.Chooser

        constructor: (@_key, @_groupN = (n) -> "[Channel#{n+1}]") ->
            @_decks = []
            @_selected = null

The **choose** method retuns a behaviour that enables the control of
the Nth group, starting from zero.  These objects can also be used
as *condition* to enable certain controls when this option is
selected.

        choose: (n) ->
            result = @_decks[n]
            if not result
                result = exports.map(@_groupN(n), @_key).transform => @select n
                @_decks[n] = result
            result

The **select** method enables the control on the Nth group.

        select: (n) ->
            @_selected = n
            for deck, n in @_decks
                deck.script?.mixxx.engine.setValue \
                    @_groupN(n), @_key, (@_selected == n)
            null

    exports.chooser = factory exports.Chooser


### Conditionals

Conditional behaviours are used to enable a *wrapped* behaviour only
under certain circumstances -- i.e. when some `behaviour.Value`
evaluates to true.  They are used to implement the `when` and `else`
methods of the `control.Control` class.

    class exports.When extends exports.Behaviour

        constructor: (@_condition, wrapped...) ->
            @else = => @_else arguments...
            @else.when = => @_elseWhen arguments...
            super()
            @_wrapped = exports.toBehaviour wrapped...
            @_condition.on 'value', => do @_update
            @_nextCondition = @_condition

        _elseWhen: (condition, args...) ->
            assert @_nextCondition?, "Can not define more conditions after 'else'"
            @_nextCondition = value.and value.not(@_nextCondition), condition
            new exports.When @_nextCondition, args...

        _else: (args...) ->
            assert @_nextCondition?, "Can not define more conditions after 'else'"
            nextCondition = value.not @_nextCondition
            @_nextCondition = undefined
            new exports.When nextCondition, args...

        enable: (args...) ->
            super
            @_enableOn = args
            @_enableRequested = true
            do @_update

        disable: ->
            @_enableRequested = false
            do @_update
            super

        _update: ->
            mustEnable = @_enableRequested and @_condition.value
            if @_wrapped.actor and not mustEnable
                @_wrapped.disable @_enableOn...
            if not @_wrapped.actor and mustEnable
                @_wrapped.enable @_enableOn...


Conditional behaviours can not be directly mapped, as they have to
determine, in the script, wether they are enabled or not.

        directOutMapping: -> null
        directInMapping: -> null

    exports.when = factory exports.When


### Special actions

    class exports.Action extends exports.Output

        minimum: true

        constructor: (@action = undefined) ->
            super()
            @onPress   or= action.press
            @onRelease or= action.release

        onEvent: (ev) ->
            val = @value = @output.value = ev.value > 0
            if val
                @onPress?()
            else
                @onRelease?()

    exports.action = factory exports.Action


**PunchIn** tries to mimic the punch-in functionaility of a mixer by setting the
crossfader to the center.  The threshold must be either positive or
negative for the left channel and indicates how far the crossfader has
to be from the center for punch-in to have effect.

    exports.punchIn = (threshold) ->
        oldxfader = undefined
        exports.action
            press: ->
                engine    = @script.mixxx.engine
                newxfader = engine.getValue "[Master]", "crossfader"
                if (threshold < 0 and newxfader < threshold) or
                        (threshold > 0 and newxfader > threshold)
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
                             alpha           = 1.0/8.0,
                             beta            = 1.0 / 8.0 / 32.0,
                             ramp            = true) ->
        exports.action
            press: ->
                enable = @script.mixxx.engine.scratchEnable
                enable deck, intervalsPerRev, rpm, alpha, beta, ramp
            release: ->
                @script.mixxx.engine.scratchDisable deck, ramp

    exports.scratchTick = (deck, transform) ->
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
