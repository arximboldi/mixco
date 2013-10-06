mixco.control
=============

Defines different hardware controls.

    {multi} = require './multi'
    {indent, hexStr, assert, factory, xmlTag, joinLn, printer} = require './util'
    behaviour = require './behaviour'
    {some, extend} = require 'underscore'

Constants
---------

    exports.MIDI_NOTE_ON   = MIDI_NOTE_ON   = 0x9
    exports.MIDI_NOTE_OFF  = MIDI_NOTE_OFF  = 0x8
    exports.MIDI_CC        = MIDI_CC        = 0xB
    exports.MIDI_PITCHBEND = MIDI_PITCHBEND = 0xE

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

    pbIds     = -> [ midiId(MIDI_PITCHBEND, 0, arguments...) ]
    noteOnIds = -> [ midiId(MIDI_NOTE_ON, arguments...) ]
    noteIds   = -> [ midiId(MIDI_NOTE_ON, arguments...)
                   , midiId(MIDI_NOTE_OFF, arguments...) ]
    ccIds     = -> [ midiId(MIDI_CC, arguments...) ]

    exports.pbIds = pbIds
    exports.noteOnIds = noteOnIds
    exports.noteIds = noteIds
    exports.ccIds = ccIds

The **event** function returns an object representing an script event
coming from Mixxx.

    exports.event = event = (channel, control, value, status, group) ->
        channel: channel
        control: control
        value: switch status >> 4
            when MIDI_PITCHBEND then (value * 128.0 + control) / 128.0
            else value
        status: status
        group: group
        message: -> @status >> 4

Controls
--------

Base class for all control types.

    class exports.Control extends behaviour.Actor

        constructor: (@ids = [midiId()], args...) ->
            @else      = => @_else arguments...
            @else.when = => @_elseWhen arguments...
            @else_     = @else
            super()
            if not (@ids instanceof Array)
                @ids = ccIds @ids, args...
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
            @_behaviours.push @registerBehaviour behaviour.toBehaviour args...
            this

        when: (args...) ->
            assert not @_isInit
            @_lastWhen = behaviour.when args...
            @_behaviours.push @registerBehaviour @_lastWhen
            this

        _elseWhen: (args...) ->
            assert @_lastWhen?,
                "'elseWhen' must be preceded by 'when' or 'elseWhen'"
            @_lastWhen = @_lastWhen.else.when args...
            @_behaviours.push @registerBehaviour @_lastWhen
            this

        _else: (args...) ->
            assert @_lastWhen?,
                "'else' must be preceded by 'when' or 'elseWhen'"
            @_lastWhen = @_lastWhen.else args...
            @_behaviours.push @registerBehaviour @_lastWhen
            @_lastWhen = undefined
            this

        init: (script) ->
            @script = script
            assert not @_isInit
            for b in @_behaviours
                b.enable script, this
            @_isInit = true

        shutdown: (script) ->
            assert script == @script
            assert @_isInit
            for b in @_behaviours
                b.disable script, this
            @_isInit = false
            delete @script

        registerBehaviour: (b) -> b
        configInputs: (depth, script) ->
        configOutputs: (depth, script) ->

### Input

An *input control* can proccess inputs from the hardware.

    class exports.InControl extends exports.Control

        init: (script) ->
            super
            if @needsHandler()
                script.registerHandler \
                    ((args...) => @emit 'event', event args...),
                    @handlerId()

A input control can be configured with the same type of *options* that
behaviours can.  These are documented in the `mixco.behaviour`
module. An *options chooser* syntax is also available.

        option: (options...) ->
            (@_options ?= []).push options...
            for beh in @_behaviours
                beh.option options...
            this

        @property 'options', -> behaviour.makeOptionsChooser @

        registerBehaviour: (beh) ->
            if @_options?
                beh.option @_options...
            beh

The control will listen to the --via a *handler*-- only when the
behaviours need it. If there is only one behaviour in the control and
this can be directly mapped, the midi messages will be connected
directly in the XML file.  Otherwise, the control will request to
process the MIDI messages via the script, and it will emit a `event`
signal when they are received.

        needsHandler: ->
            @_behaviours.length != 1 or
                not @_behaviours[0].directInMapping() or
                some @_behaviours[0]._options, (opt) -> not opt.name

        handlerId: ->
            "x#{@ids[0].status().toString(16)}_x#{@ids[0].midino.toString(16)}"

        configInputs: (depth, script) ->
            if @needsHandler()
                mapping =
                    group: "[Master]"
                    key:   script.handlerKey @handlerId()
            else
                mapping = @_behaviours[0].directInMapping()
            joinLn(@configInMapping depth, mapping, id for id in @ids)

        configInMapping: (depth, mapping, id) ->
            """
            #{indent depth}<control>
            #{indent depth+1}<group>#{mapping.group}</group>
            #{indent depth+1}<key>#{mapping.key}</key>
            #{id.configMidi depth+1}
            #{indent depth+1}<options>
            #{@configOptions depth+2}
            #{indent depth+1}</options>
            #{indent depth}</control>
            """

        configOptions: (depth) ->
            if @needsHandler()
                "#{indent depth}<script-binding/>"
            else if @_behaviours[0]._options?.length > 0
                joinLn(
                    for opt in @_behaviours[0]._options
                        if opt.name?
                            "#{indent depth}<#{opt.name}/>")
            else
                "#{indent depth}<normal/>"

### Output

An *output control* can send data to the hardware.

    class exports.OutControl extends exports.Control

        constructor: ->
            super
            @_states =
                on:      0x7f
                off:     0x00
                disable: 0x00

        send: (state) ->
            @doSend state

        states: (states) ->
            extend @_states, states
            @

        doSend: (state) ->
            id = @ids[0]
            if state of @_states
                @script.mixxx.midi.sendShortMsg \
                    id.status(), id.midino, @_states[state]
            else
                @script.mixxx.midi.sendShortMsg \
                    id.status(), id.midino, state

        init: ->

We should remove the send function before enabling behaviours.

            if not @needsSend()
                @send = undefined
            super

        shutdown: ->
            @doSend 'disable'
            super

        needsSend: ->
            @_behaviours.length != 1 or
            not @_behaviours[0].directOutMapping()

        configOutputs: (depth, script) ->
            mapping = not @needsSend() and @_behaviours[0].directOutMapping()
            if mapping
                joinLn(@configOutMapping depth, mapping, id for id in @ids)

        configOutMapping: (depth, mapping, id) ->
            if id.message != MIDI_NOTE_OFF
                options = joinLn [
                    xmlTag 'minimum', mapping.minimum, depth+1
                    xmlTag 'maximum', mapping.maximum, depth+1
                ]
                """
                #{indent depth}<output>
                #{indent depth+1}<group>#{mapping.group}</group>
                #{indent depth+1}<key>#{mapping.key}</key>
                #{id.configMidi depth+1}
                #{indent depth+1}<on>#{hexStr @_states['on']}</on>
                #{indent depth+1}<off>#{hexStr @_states['off']}</off>
                #{options}
                #{indent depth}</output>
                """

### Concrete controls

#### Aliases

Lets provide a series of aliases to make scripts read more natural,
and maybe also eventually add specifics to these.

    exports.input  = factory exports.InControl
    exports.output = factory exports.OutControl
    exports.knob   = exports.input
    exports.slider = exports.knob
    exports.button = ->
        exports.input(arguments...)
            .options.button
    exports.encoder = ->
        exports.input(arguments...)
            .options.diff
    exports.meter  = exports.output


#### Input and output

Represents a hardware control that can do both input and output.  This
is often the case for buttons that have a LED.

    class exports.InOutControl extends multi exports.InControl,
                                             exports.OutControl

    exports.control   = factory exports.InOutControl
    exports.ledButton = ->
        exports.control(arguments...)
            .option behaviour.option.button



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
