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

    transform = require('./transform')
    util = require('./util')
    indent = util.indent


Outputs
-------

Outputs are provided by controls and used by behaviours to define the
state if LEDs and so on.


    class exports.Output

        send: (state) ->


Behaviours
----------

A behaviour determines how a control should behave under some
circunstances.

    class exports.Behaviour

        onEvent: (ev) ->
        enable: ->
        disable: ->

Define a **directMapping** when the Behaviour can be mapped directly
to a Mixxx control. Note that this should not depend on conditions
determined after the XML configuration is generated.

        directInMapping: -> null
        directOutMapping: -> null

The output of the behaviour is set by the controls that it is
associated to.

        output: new exports.Output

        configOutput: (depth) ->


### Map

The **map** behaviours maps the control directly to a control in
Mixxx.

    class exports.Map extends exports.Behaviour

        minimum: 1

        constructor: (@group, @key) ->

        enable: ->
            super
            @update()

        disable: ->
            super

Update the output to match the current value in the engine.

        update: ->
            value = engine.getValue(@group, @key)
            @output.send \
                if value >= @minimum
                    @output.onValue
                else
                    @output.offValue

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
starting from zero.

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
