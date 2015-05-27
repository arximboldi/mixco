spec.mock
=========

*Mocks* for objects provided by the Mixxx context. Please *update them
when needed*, reflecting [the official Mixxx documentation](
http://mixxx.org/wiki/doku.php/midi_scripting).

    script = require '../src/script'
    {assert} = require '../src/util'
    {spy} = require 'sinon'

Engine
------

    exports.engine = ->
        values = {}
        connections = {}
        softTakeover: spy ->   # (group, key, enable)
        beginTimer: spy ->     # (delay, handler) -> id
        stopTimer: spy ->      # (id)
        scratchEnable: spy ->  # (int deck, int intervalsPerRev, float rpm,
                               #  alpha, beta, ramp)
        scratchTick: spy ->    # (int deck, int interval)
        scratchDisable: spy -> # (int deck)
        isScratching: spy ->   # (int deck)
        brake: spy ->          # (int deck, bool activate[, float factor, rate])
        spinback: spy ->       # (int deck, bool activate[, float factor, rate])
        getValue: spy (group, key) ->
            values[[group, key]] ? 0
        setValue: spy (group, key, value) ->
            values[[group, key]] = value
        connectControl: spy (group, key, handler, disconnect) ->
            id = [group, key, handler]
            if disconnect
                assert id of connections,
                    "Disconnect not connect control: #{group}, #{key}"
                delete connections[id]
            else
                assert id not of connections,
                    "Connect connected control: #{group}, #{key}"
                connections[id] = true

Midi
----

    exports.midi = ->
        sendShortMsg: spy -> # (status, id, value)
        sendSysexMsg: spy -> # (data, length)

Midi
----

    exports.script = ->
        pitch: spy (control, value, status) ->


Fake mixxx object
-----------------

    exports.mixxx = ->
        engine: exports.engine()
        midi:   exports.midi()
        script: exports.script()

Script
------

This test script class provides Mixxx object mocks.

    class exports.TestScript extends script.Script

        @property 'mixxx',
            get: ->
                @_fakeMixxx or= exports.mixxx()

    exports.testScript = -> new exports.TestScript arguments...


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
