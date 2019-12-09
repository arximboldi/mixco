# spec.scripts
# ============
#
# > This file is part of the [Mixco framework](http://sinusoid.es/mixco).
# > - **View me [on a static web](http://sinusoid.es/mixco/test/scripts.spec.html)**
# > - **View me [on GitHub](https://github.com/arximboldi/mixco/blob/master/test/scripts.spec.coffee)**
#
# General tests for some of the Mixco based scripts.  This will test
# every available script in the 'script' folder at the root of the
# Mixco distribution.

{expect} = require 'chai'
globby = require 'globby'

describe 'scripts', ->

    fs       = require 'fs'
    path     = require 'path'
    mock     = require './mock'
    mixco    = require 'mixco'
    {assert} = mixco.util

    MIXCO_EXT_GLOBS = [
        "*.mixco.js"
        "*.mixco.coffee"
        "*.mixco.litcoffee"
    ]

    # One may use the MIXCO_TEST_INPUTS environment variable to pass
    # which scripts to test.  This variable should contain a
    # `:`-separated list of globby globs.

    MIXCO_TEST_INPUTS  = process.env.MIXCO_TEST_INPUTS?.split ':'
        .map (input) -> path.resolve process.cwd(), input
    MIXCO_TEST_INPUTS ?= MIXCO_EXT_GLOBS.map (ext) ->
            path.join __dirname, "..", "script", "**", ext

    # We should let exception get all the way down to the test
    # framework so trivial errors are detected. The **unrequire**
    # function will cause a module to be unloaded.  We patch the
    # *catching* decorator after unloading all modules so exceptions
    # reach the test system.

    unrequire = (name) ->
        fullName = require.resolve name
        if fullName of require.cache
            delete require.cache[fullName]

    globEach = (globs, fn) ->
        # Registering tests asynchronously confuses Mocha
        globby.sync globs
            .forEach fn

    do monkeypatchCatching = ->
        unrequire 'heterarchy'
        unrequire 'mixco'
        globEach MIXCO_TEST_INPUTS, (fname) ->
            unrequire fname
        globEach ['../lib/*.js', '../src/*.litcoffee'], (fname) ->
            unrequire fname

        require 'mixco'
        ['../src/util', '../lib/util'].forEach (mname) ->
            module = require.cache[require.resolve mname]
            module?.exports.catching = (f) -> f

    # Tests
    # -----
    #
    # For every possible script we find, we generate some tests that
    # will check for stupid JavaScript programming mistakes -- like
    # propagating `undefined` values -- or other potential errors,
    # like exceptions reaching Mixxx, or whatever.

    globEach MIXCO_TEST_INPUTS, (fname) ->
        scriptName = path.basename fname, path.extname fname
        scriptName = path.basename scriptName, ".mixco"

        describe "#{scriptName}", ->
            script = null

            beforeEach ->
                @timeout 1 << 14
                unrequire fname
                module = require fname
                script = module[scriptName]
                script.mixxx = mock.mixxx()

            it "generates configuration without undefined values", ->
                expect(script.config())
                    .not.to.match /undefined/
                expect(script.config())
                    .not.to.match /NaN/

            it "is not empty", ->
                expect(script.controls.length)
                    .not.to.equal 0

            it "initializes and shutsdown without launching exceptions", ->
                script.init()
                script.shutdown()

            # The next is specially useful.  Missing entries in the
            # `mixco.transform` table are often found by these, among
            # other trivial problems in the user scripts.
            #
            # We simulate here that we send values to all controls
            # that are script mapped.  We run through the controls in
            # different orders, increasing the likelihood of executing
            # behaviours that lie under modifiers.  Note the check
            # `ev.value == value` after creating the event -- this way
            # we prevent sending the *note off* message of some
            # buttons when we do not intend to.

            it "does not break when receiving MIDI", ->
                @timeout 1 << 14
                control  = require '../src/control'
                sendValues = (values, order=1) ->
                    for c in script.controls by order
                        if c.needsHandler?()
                            for id in c.ids
                                for value in values
                                    ev = control.event \
                                        id.channel,
                                        null,
                                        value,
                                        id.status(),
                                        null
                                    if ev.value == value
                                        c.emit 'event', ev
                script.init()
                sendValues [127, 63, 0]
                sendValues [127, 63, 0], -1
                sendValues [127]
                sendValues [127], -1
                sendValues [0], -1
                sendValues [0]
                script.shutdown()

# License
# -------
#
# >  Copyright (C) 2013 Juan Pedro Bolívar Puente
# >
# >  This program is free software: you can redistribute it and/or
# >  modify it under the terms of the GNU General Public License as
# >  published by the Free Software Foundation, either version 3 of the
# >  License, or (at your option) any later version.
# >
# >  This program is distributed in the hope that it will be useful,
# >  but WITHOUT ANY WARRANTY; without even the implied warranty of
# >  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# >  GNU General Public License for more details.
# >
# >  You should have received a copy of the GNU General Public License
# >  along with this program.  If not, see <http://www.gnu.org/licenses/>.
