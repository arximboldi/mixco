spec.mock
=========

*Mocks* for objects provided by the Mixxx context. Please *update them
when needed*, reflecting [the official Mixxx documentation](
http://mixxx.org/wiki/doku.php/midi_scripting).

Dependencies
------------

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
