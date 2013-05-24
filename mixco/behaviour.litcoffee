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

    util = require('./util')
    transform = require('./transform')

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

### Map

The **map** behaviours maps the control directly to a control in
Mixxx.

    class exports.Map extends exports.Behaviour

        constructor: (@group, @key) ->

Enables soft takeover.

        soft: ->
            @_soft = true
            this

        enable: ->
            super
            engine.softTakeover(@group, @key, @_soft)

        disable: ->
            super
            engine.softTakeover(@group, @key, false)

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


    exports.map = -> new exports.Map arguments...
