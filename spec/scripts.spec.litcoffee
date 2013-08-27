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
