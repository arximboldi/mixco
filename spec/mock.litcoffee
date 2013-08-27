spec.mock
=========

*Mocks* for objects provided by the Mixxx context. Please *update them
when needed*, reflecting [the official Mixxx documentation](
http://mixxx.org/wiki/doku.php/midi_scripting).

    script = require '../mixco/script'

Engine
------

    exports.engine = ->
        createSpyObj 'engine', [
            'getValue',       # (group, key)
            'setValue',       # (group, key, value)
            'softTakeover',   # (group, key, enable)
            'connectControl', # (group, key, handler[, disconnnect])
            'scratchEnable',  # (int deck, int intervalsPerRev, float rpm,
                              #  alpha, beta, ramp)
            'scratchTick',    # (int deck, int interval)
            'scratchDisable', # (int deck)
            'isScratching',   # (int deck)
            ]

Midi
----

    exports.midi = ->
        createSpyObj 'engine', [
            'sendShortMsg',     # (status, id, value)
            'sendSysexMessage', # (data, length)
            ]


Midi
----

    exports.script = ->
        createSpyObj "script", [
            'pitch', # (control, value, status)
            ]


Fake mixxx object
-----------------

    exports.mixxx = ->
        engine: do exports.engine
        midi:   do exports.midi
        script: do exports.script

Script
------

This test script class provides Mixxx object mocks.

    class exports.TestScript extends script.Script

        @property 'mixxx',
            get: ->
                @_fakeMixxx or= do exports.mixxx

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
