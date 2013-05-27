mixco.behaviour
===============

Set of classes determining what controls do.

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

    events = require('events')
    transform = require('./transform')
    util = require('./util')
    indent = util.indent
    assert = util.assert


Value
-----

The **Value** instances represent an active value that changes with
time.  The actual value can be accessed via the `value` property.
Whenever the value changes, a `value` event is notified, using the
standard node.js event system.  To register a listener callback that
is called whenever the value changes, use the `on` method from the
`events.EventEmitter` interface.

    class Value extends events.EventEmitter

        constructor: (initial=undefined) ->
            if initial?
                @value = initial

        @property 'value',
            get: -> @_value
            set: (newValue) ->
                if @_value != newValue
                    @_value = newValue
                    @emit 'value', newValue
                @_value

Actor
-----

An **Actor** is the basic object that we want to add behaviours to.
In general, they are *controls*, as defined by the `mixco.control`
module.  They have an `event` event, however, it is not guaranteed to
be emitted if the interface decides that direct mappings suffice.

    class exports.Actor extends events.EventEmitter

        send: (state) ->



Behaviours
----------

A **Behaviour** determines how a control should behave under some
circunstances. In general, behaviours are values also, so one can
listen to them.

    class exports.Behaviour extends Value

Behaviours can be enabled or disabled, to determine the behaviour of a
given actor.

        enable: (script, actor) ->
            assert not @actor?
            @actor = actor
            @_eventListener = (ev) => @onEvent ev
            actor.addListener 'event', @_eventListener

        disable: (script, actor) ->
            assert @actor == actor
            actor.removeListener 'event', @_eventListener
            @actor = undefined

Define a **directMapping** when the Behaviour can be mapped directly
to a Mixxx actor. Note that this should not depend on conditions
determined after the XML configuration is generated.

        directInMapping: -> null
        directOutMapping: -> null

        configOutput: (depth) ->

        onEvent: (ev) -> null


### Map

The **map** behaviours maps the control directly to a control in
Mixxx.  If the value is listened to, then it will

    class exports.Map extends exports.Behaviour

        minimum: 1

        constructor: (@group, @key) ->

        enable: (script) ->
            super
            @value = engine.getValue @group, @key
            @updateOutput()
            if @listeners('value') > 0 and not @_valueHandlerConnected
                @_valueHandler or= script.registerHandler (v) => @value = v
                engine.connectControl @group, @key, @_valueHandler
                @_valueHandlerConnected = true

        disable: (script) ->
            super
            if @_valueHandlerConnected?
                engine.connectControl @group, @key, @_valueHandler, true


Update the output to match the current value in the engine.

        updateOutput: ->
            @actor?.send if @value >= @minimum then 'on' else 'off'

        directInMapping: ->
            group: @group
            key:   @key

        directOutMapping: ->
            group: @group
            key:   @key

While in general mappings are done directly, bypassing the script,
under some circunstances it might happen that they are proccessed in
the script.  In this case, we define `onEvent` to emulate the
behaviour of a direct mapping.

        onEvent: (ev) ->
            value = transform.mappings[@key](ev.value)
            engine.setValue @group, @key, value

        configOutput: (depth) ->
            "#{indent depth}<minimum>#{@minimum}</minimum>"


    exports.map  = -> new exports.Map arguments...


The **toBehaviour** factory that builds a default behaviour from a set
of arguments.  If the arguments is just a behaviour, returns it.

    exports.toBehaviour = (behaviour, args...) ->
        if not (behaviour instanceof exports.Behaviour)
            exports.map behaviour, args...
        else
            behaviour


The **Soft** behaviour defines a mapping with soft takeover enabled.

    class exports.Soft extends exports.Map

        enable: ->
            super
            engine.softTakeover(@group, @key, true)

        disable: ->
            super
            engine.softTakeover(@group, @key, false)

When soft takeover is enabled we have to process the events through
the script.

        directInMapping: -> null

    exports.soft = -> new exports.Soft arguments...


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


### Chooser

The **Chooser* lets you select a 'binary' proparty of the decks that
are registered exclusively, such that is enabled only in one at a
time.

    class exports.Chooser

        constructor: (@_key, @_groupN = (n) -> "[Channel#{n+1}]") ->
            @_decks = []
            @_selected = null

**choose** retuns a behaviour that selects the Pfl of the Nth channel,
starting from zero.  These behaviours can also be used as condition.

        choose: (n) ->
            result = @_decks[n]
            if not result
                result = new Action (=> @select n), @_groupN(n), @_key
                @_decks[n] = result
            result

        select: (n) ->
            @_selected = n
            for _, n in @_decks
                engine.setValue @_groupN(n), @_key, (@_selected == n)

    exports.chooser = -> new exports.Chooser arguments...
