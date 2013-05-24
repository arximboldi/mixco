mixco.transform
===============

Methods to transform MIDI values to Mixxx control values.

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
    indent = util.indent
    hexStr = util.hexStr


Constants
---------

    MIDI_NOTE_ON  = 0x8
    MIDI_NOTE_OFF = 0x9
    MIDI_CC       = 0xB


Utilities
---------

The **midi** function returns an object representing a MIDI identifier
for a control.

    midi = (midino = 0, channel = 0) ->
        midino: midino
        channel: channel
        status: (message) -> (message << 4) | @channel
        configMidi: (message, depth) ->
            """
            #{indent depth}<status>#{hexStr @status(message)}</status>
            #{indent depth}<midino>#{hexStr @midino}</midino>
            """

Controls
--------

Base class for all control types.

    class exports.Control

        constructor: (@id=midi()) ->
            if not (@id instanceof Object)
                @id = midi @id


Define the behaviour of the control.

        does: (behaviour) ->
            @_behaviour = behaviour
            this

Called when the control received a MIDI event and is processed via the
script. By default, tries to do the same as if the control were mapped
directly.

        onScript: (ev) ->
            @_behaviour.onScript ev

        init: (script) ->
            if @_isScripted()
                script.registerScripted this, @_scriptedId()
            @_behaviour.enable()

        shutdown: (script) ->
            @_behaviour.disable()

        configInputs: (depth, script) ->
            if @_isScripted()
                mapping =
                    group: ""
                    key:   script.scriptedKey(@_scriptedId())
            else
                mapping = @_behaviour.directInMapping()
            """
            #{indent depth}<control>
            #{indent depth+1}<group>#{mapping.group}</group>
            #{indent depth+1}<key>#{mapping.key}</key>
            #{@id.configMidi @message, depth+1}
            #{indent depth+1}<options>
            #{@_configOptions depth+2}
            #{indent depth+1}</options>
            #{indent depth}</control>
            """

        configOutputs: (depth, script) ->

        configOptions: (depth) ->
            "#{indent depth}<normal/>"

        _configOptions: (depth) ->
            if @_isScripted()
                "#{indent depth}<script-binding/>"
            else
                @configOptions depth

        _isScripted: -> not @_behaviour?.directInMapping()

        _scriptedId: -> util.mangle \
            "_#{@group}_#{@id.midino}_#{@id.status @message}"


### Knob

Represents a basic hardware element for setting continuous parameters
-- e.g, a knob or slider.

    class exports.Knob extends exports.Control

        message: MIDI_CC

I hate using the **new** operator, thus for every concrete control
we'll provide some factory functions.

    exports.knob = -> new exports.Knob arguments...
    exports.slider = exports.knob


### Button

Represents a hardware button.

    class exports.Button extends exports.Control
        message: MIDI_CC

        configOptions: (depth) ->
            "#{indent depth}<button/>"

    exports.button = -> new exports.Button arguments...


### LedButton

Represents a hardware button with a LED that should be turned on to
represent the boolean property that it is mapped to.

    class exports.LedButton extends exports.Button

        onValue: 0x7f
        offValue: 0x00

        configOutputs: (depth, script) ->
            if @_behaviour
                mapping = @_behaviour.directOutMapping()
                if mapping
                    """
                    #{indent depth}<output>
                    #{indent depth+1}<group>#{mapping.group}</group>
                    #{indent depth+1}<key>#{mapping.key}</key>
                    #{@id.configMidi @message, depth+1}
                    #{indent depth+1}<on>#{hexStr @onValue}</on>
                    #{indent depth+1}<off>#{hexStr @offValue}</off>
                    #{indent depth+1}<minimum>1</minimum>
                    #{indent depth}</output>
                    """

    exports.ledButton = -> new exports.LedButton arguments...
