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
            ]

Midi
----

    exports.midi = ->
        createSpyObj 'engine', [
            'sendShortMsg',     # (status, id, value)
            'sendSysexMessage', # (data, length)
            ]

Script
------

This test script class provides Mixxx object mocks.

    class exports.TestScript extends script.Script

        @property 'mixxx',
            get: ->
                @_fakeMixxx or=
                    engine: do exports.engine
                    midi:   do exports.midi

    exports.testScript = -> new exports.TestScript arguments...
