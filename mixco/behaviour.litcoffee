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
            @script.mixxx.engine.setValue @group, @key, @_transform ev.value

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


### Actions

Actions let you set a callback.  Still, they are map, so you can
associate a value that can be associated to it.

    class Action extends exports.Map

        constructor: (@action, args...) ->
            super args...

        onEvent: (ev) ->
            if ev.value
                @action()

        directInMapping: ->


    class exports.Set extends Action

        constructor: (@valueToSet, args...) ->
            super (=>
                engine.setValue @group, @key, @valueToSet), args...

    exports.set = -> new exports.Set arguments...


    class exports.Toggle extends exports.Map

        constructor: (@setOffValue, @setOnValue, args...) ->
            super args...

        onEvent: (ev) ->
            val = if ev.value then @setOnValue else @setOffValue
            engine.setValue @group, @key, val

        directInMapping: ->

    exports.toggle = -> new exports.Toggle arguments...


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
                result = new Action (=> @select n), @_groupN(n), @_key
                @_decks[n] = result
            result

The **select** method enables the control on the Nth group.

        select: (n) ->
            @_selected = n
            for deck, n in @_decks
                deck.script?.mixxx.engine.setValue @_groupN(n), @_key, (@_selected == n)

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
            super args...
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


### Special functionality

Tries to mimic the punch-in functionaility of a mixer by setting the
crossfader to the center.  The threshold must be either positive or
negative for the left channel and indicates how far the crossfader has
to be from the center for punch-in to have effect.

    class exports.PunchIn extends exports.Output

        minimum: true

        constructor: (@threshold) ->
            super()

        onEvent: (ev) ->
            val = @value = @output.value = ev.value > 0
            engine = @script.mixxx.engine
            if val
                oldfader = engine.getValue "[Master]", "crossfader"
                if (@threshold < 0 and oldfader < @threshold) or
                        (@threshold > 0 and oldfader > @threshold)
                    @_oldfader = oldfader
                    engine.setValue "[Master]", "crossfader", 0
            else
                if @_oldfader?
                    engine.setValue "[Master]", "crossfader", @_oldfader
                    @_oldfader = undefined

        directOutMapping: -> null
        directInMapping: -> null

    exports.punchIn = -> new exports.PunchIn arguments...


The **ScratchEnable** and **ScratchTick** behaviour map to the
engine scratch system.

    class exports.ScratchEnable extends exports.Output

        minimum: true

        constructor: (@scratchDeck,
                      @scratchIntervalsPerRev = 128*4,
                      @scratchRpm             = 44.0,
                      @scratchAlpha           = 1.0/8.0,
                      @scratchBeta            = 1.0 / 8.0 / 32.0,
                      @scratchRamp            = true) ->
            super()

        onEvent: (ev) ->
            val = @value = @output.value = ev.value > 0
            engine = @script.mixxx.engine
            if val
                engine.scratchEnable @scratchDeck, @scratchIntervalsPerRev,
                                     @scratchRpm, @scratchAlpha, @scratchBeta,
                                     @scratchRamp
            else
                engine.scratchDisable @scratchDeck, @scratchRamp

        directOutMapping: -> null
        directInMapping: -> null

    exports.scratchEnable = -> new exports.ScratchEnable arguments...


    class exports.ScratchTick extends exports.Output

        constructor: (@scratchDeck,
                      @scratchTransform = (val) -> val) ->
            super()

        onEvent: (ev) ->
            val = @value = @output.value = ev.value
            engine = @script.mixxx.engine
            engine.scratchTick @scratchDeck, @scratchTransform val

        directOutMapping: -> null
        directInMapping: -> null

    exports.scratchTick = -> new exports.ScratchTick arguments...
