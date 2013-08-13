mixco.control
=============

Defines different hardware controls.

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

    util      = require './util'
    behaviour = require './behaviour'

    indent = util.indent
    hexStr = util.hexStr
    assert = util.assert


Constants
---------

    MIDI_NOTE_ON  = 0x9
    MIDI_NOTE_OFF = 0x8
    MIDI_CC       = 0xB


Utilities
---------

The **midi** function returns an object representing a MIDI identifier
for a control.

    midiId = (message = MIDI_CC, midino = 0, channel = 0) ->
        message: message
        midino:  midino
        channel: channel
        status: -> (@message << 4) | @channel
        configMidi: (depth) ->
            """
            #{indent depth}<status>#{hexStr @status()}</status>
            #{indent depth}<midino>#{hexStr @midino}</midino>
            """
    exports.midiId = midiId

The **noteIds** and **ccIds** returns a list with the MIDI messages
needed to identify a control based on notes or control signals.

    noteOnIds = -> [ midiId(MIDI_NOTE_ON, arguments...) ]
    noteIds   = -> [ midiId(MIDI_NOTE_ON, arguments...)
                   , midiId(MIDI_NOTE_OFF, arguments...) ]
    ccIds     = -> [ midiId(MIDI_CC, arguments...) ]

    exports.noteOnIds = noteOnIds
    exports.noteIds = noteIds
    exports.ccIds = ccIds

The **event** function returns an object representing an script event
coming from Mixxx.

    event = (channel, control, value, status, group) ->
        channel: channel
        control: control
        value: if status >> 4 != MIDI_NOTE_OFF then value else 0
        status: status
        group: group
        message: -> @status >> 4

Controls
--------

Base class for all control types.

    class exports.Control extends behaviour.Actor

        constructor: (@ids = [midiId()]) ->
            if not (@ids instanceof Array)
                @ids = ccIds @id
            @_behaviours = []

The following set of methods define the behaviour of the control. A
control can have several behaviours at the same time. Note that when
passing behaviours to these methods (which is always the last
parameter) you can either pass a *Behaviour* object or a *key* and
*group* strings that will be puto directly into a `behaviour.map`.

Thera are three kinds of behaviours we can associate to the control:

* With **does** we associate behaviours that are always *active*,
  unconditionally.

* With **when** we associate behaviours that are only *active* when some
  condition is met.  This `condition` is a boolean `behaviour.Value`
  object.

* With **else** we associate behaviours that are only active when no
  other *when* behaviour is *active*.

        does: (args...) ->
            assert not @_isInit
            @_behaviours.push behaviour.toBehaviour args...
            this

        when: (args...) ->
            assert not @_isInit
            @_lastWhen = behaviour.when args...
            @_behaviours.push @_lastWhen
            this

        elseWhen: (args...) ->
            assert @_lastWhen?, "'else' must be preceded by 'when' or 'elseWhen'"
            @_lastWhen = @_lastWhen.elseWhen args...
            @_behaviours.push @_lastWhen
            this

        else: (args...) ->
            assert @_lastWhen?, "'else' must be preceded by 'when' or 'elseWhen'"
            @_lastWhen = @_lastWhen.else args...
            @_behaviours.push @_lastWhen
            @_lastWhen = undefined
            this


The control will listen to the --via a *handler*-- only when the
behaviours need it. If there is only one behaviour in the control and
this can be directly mapped, the midi messages will be connected
directly in the XML file.  Otherwise, the control will request to
process the MIDI messages via the script, and it will emit a `event`
signal when they are received.

        needsHandler: ->
            @_behaviours.length != 1 or not do @_behaviours[0].directInMapping

        handlerId: -> util.mangle \
            "#{@ids[0].midino}_#{@ids[0].status @message}"

        init: (script) ->
            assert not @_isInit
            if do @needsHandler
                script.registerHandler \
                    ((args...) => @emit 'event', event args...),
                    @handlerId()
            for b in @_behaviours
                b.enable script, this
            @_isInit = true

        shutdown: (script) ->
            assert @_isInit
            for b in @_behaviours
                b.disable script, this
            @_isInit = false

        configInputs: (depth, script) ->
            if do @needsHandler
                mapping =
                    group: "[Master]"
                    key:   script.handlerKey do @handlerId
            else
                mapping = do @_behaviours[0].directInMapping
            (@configInMapping depth, mapping, id for id in @ids)
                .filter((x)->x)
                .join('\n')

        configInMapping: (depth, mapping, id) ->
            """
            #{indent depth}<control>
            #{indent depth+1}<group>#{mapping.group}</group>
            #{indent depth+1}<key>#{mapping.key}</key>
            #{id.configMidi depth+1}
            #{indent depth+1}<options>
            #{@_configOptions depth+2}
            #{indent depth+1}</options>
            #{indent depth}</control>
            """

        configOutputs: (depth, script) ->

        configOptions: (depth) ->
            "#{indent depth}<normal/>"

        _configOptions: (depth) ->
            if do @needsHandler
                "#{indent depth}<script-binding/>"
            else
                @configOptions depth


### Knob

Represents a basic hardware element for setting continuous parameters
-- e.g, a knob or slider.

    class exports.Knob extends exports.Control


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

        states:
            on: 0x7f
            off: 0x00

        send: (value) ->
            @doSend value

        doSend: (state) ->
            id = @ids[0]
            midi.sendShortMsg id.status(), id.midino, @states[state]

        init: ->
            # We should remove the send function before enabling
            # behaviours.
            if not @needsSend
                @send = undefined
            super

        shutdown: ->
            super
            @doSend 'off'

        @property 'needsSend',
            get: -> @_behaviours.length != 1 or not do @_behaviours[0].directOutMapping

        configOutputs: (depth, script) ->
            mapping = not @needsSend and do @_behaviours[0].directOutMapping
            if mapping
                """
                #{indent depth}<output>
                #{indent depth+1}<group>#{mapping.group}</group>
                #{indent depth+1}<key>#{mapping.key}</key>
                #{@ids[0].configMidi depth+1}
                #{indent depth+1}<on>#{hexStr @states['on']}</on>
                #{indent depth+1}<off>#{hexStr @states['off']}</off>
                #{@_behaviours[0].configOutput depth+1}
                #{indent depth}</output>
                """

    exports.ledButton = -> new exports.LedButton arguments...
