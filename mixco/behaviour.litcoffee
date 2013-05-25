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

        onScript: (ev) ->
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

Enables soft takeover.

        soft: ->
            @_soft = true
            this

        enable: ->
            super
            engine.softTakeover(@group, @key, @_soft)
            @update()

        disable: ->
            super
            engine.softTakeover(@group, @key, false)

Update the output to match the current value in the engine.

        update: ->
            value = engine.getValue(@group, @key)
            @output.send \
                if value >= @minimum
                    @output.onValue
                else
                    @output.offValue

When soft takeover is enabled we have to process the events through
the script.

        directInMapping: ->
            if not @_soft
                group: @group
                key:   @key

        directOutMapping: ->
            group: @group
            key:   @key

        onScript: (ev) ->
            value = transform.mappings[@key](ev.value)
            engine.setValue @group, @key, value

        configOutput: (depth) ->
            "#{indent depth}<minimum>#{@minimum}</minimum>"


    exports.map  = -> new exports.Map arguments...
    exports.soft = -> exports.map(arguments...).soft()
