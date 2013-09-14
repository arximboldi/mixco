spec.mixco.value
================

General tests for some of the Mixco based scripts.

    fs       = require 'fs'
    path     = require 'path'
    mock     = require './mock'
    {assert} = require '../mixco/util'

We should let exception get all the way down to the test framework so
trivial errors are detected. The **unrequire** function will cause a
module to be unloaded.  We patch the *catching* decorator after
unloading all modules so exceptions reach the test system.

    unrequire = (name, force=false) ->
        fullName = require.resolve name
        if fullName of require.cache
            delete require.cache[fullName]

    forEveryModuleInDir = (dirs..., fn) ->
        module_exts = [ '.coffee', '.litcoffee' ]
        current_dir = path.basename require.resolve './scripts.spec.litcoffee'
        for dir in dirs
            for file in fs.readdirSync path.join current_dir, dir
                ext = path.extname file
                if ext in module_exts
                    fn path.basename(file, ext), dir

    do monkeypatchCatching = ->
        forEveryModuleInDir '../mixco', '../script', (name, dir) ->
            unrequire path.join(dir, name), true
        require '../mixco/util'
        module = require.cache[require.resolve '../mixco/util']
        module.exports.catching = (f) -> f

Tests
-----

    forEveryModuleInDir '../script', (scriptName) ->

        describe "Script: #{scriptName}", ->
            script = null

            beforeEach ->
                moduleName = path.join '../script', scriptName
                unrequire moduleName
                module = require moduleName
                script = module[scriptName]
                script.mixxx = do mock.mixxx

            it "generates configuration without undefined values", ->
                expect(do script.config)
                    .not.toMatch "undefined"

            it "initializes and shutsdown without launching exceptions", ->
                do script.init
                do script.shutdown

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
