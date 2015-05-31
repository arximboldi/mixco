# spec.scripts
# ============
#
# General tests for some of the Mixco based scripts.  This will test
# every available script in the 'script' folder at the root of the
# Mixco distribution.

{expect} = require 'chai'

describe 'scripts', ->

    fs       = require 'fs'
    path     = require 'path'
    mock     = require './mock'
    {assert} = require '../src/util'

    # We should let exception get all the way down to the test
    # framework so trivial errors are detected. The **unrequire**
    # function will cause a module to be unloaded.  We patch the
    # *catching* decorator after unloading all modules so exceptions
    # reach the test system.

    unrequire = (name, force=false) ->
        fullName = require.resolve name
        if fullName of require.cache
            delete require.cache[fullName]

    forEveryModuleInDir = (dirs..., fn) ->
        module_exts = [ '.coffee', '.litcoffee', '.js' ]
        current_dir = path.basename require.resolve './scripts.spec'
        for dir in dirs
            for file in fs.readdirSync path.join current_dir, dir
                ext = path.extname file
                if ext in module_exts
                    fn path.basename(file, ext), dir

    do monkeypatchCatching = ->
        unrequire 'heterarchy'
        forEveryModuleInDir '../src', '../script', (name, dir) ->
            unrequire path.join(dir, name), true
        require '../src/util'
        module = require.cache[require.resolve '../src/util']
        module.exports.catching = (f) -> f

    # Tests
    # -----
    #
    # For every possible script we find, we generate some tests that
    # will check for stupid JavaScript programming mistakes -- like
    # propagating `undefined` values -- or other potential errors,
    # like exceptions reaching Mixxx, or whatever.

    forEveryModuleInDir '../script', (scriptName) ->

        describe "#{scriptName}", ->
            script = null

            beforeEach ->
                moduleName = path.join '../script', "#{scriptName}"
                unrequire moduleName
                module = require moduleName
                {nameFromFilename} = require '../src/script'
                script = module[nameFromFilename scriptName]
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

            # The next is specially usefull.  Missing entries in the
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
