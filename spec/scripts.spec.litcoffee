spec.mixco.value
================

General tests for some of the Mixco based scripts.

Dependencies
------------

We should let exception get all the way down to the test framework so
trivial errors are detected. We clear all the *mixco* modules in the
*require* cache to make sure the monkeypatched version of the
*catching* function is used.  Then we patch it.

    for name, module of require.cache
        if name.match("mixco")
            delete require.cache[name]

    util = require('../mixco/util')
    for name, module of require.cache
        if name.match("mixco/util")
            module.exports.catching = (f) -> f

And some mocks of the Mixxx environment.

    mock = require('./mock')

Tests
-----

    runBasicScriptTest = (script_name) ->
        module = require("../script/#{script_name}")
        script = module[script_name]
        expect(do script.config)
            .not.toMatch "undefined"

        script.mixxx = do mock.mixxx
        do script.init
        do script.shutdown


    runBasicScriptTests = (script_names...) ->
        for script_name in script_names
            runBasicScriptTest script_name

    describe 'Scripts', ->

        it 'can run without being trivially broken', ->
           runBasicScriptTests "nanokontrol2", \
                               "xponent"
