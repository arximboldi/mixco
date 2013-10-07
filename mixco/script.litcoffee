mixco.script
============

This module contains the main interface for defining custom Mixxx
scripts.

    {flatten, bind} = require 'underscore'
    {issubclass, mro} = require './multi'
    {Control} = require './control'
    {indent, xmlEscape, catching, assert} = require './util'
    require './console'

Script
------

First, the **register** function registers a instance of the class
`scriptTypeOrDefinition` instance into the given module.
`scriptTypeOrDefinition` can be either a `Script` subclass or an
object definining overrides for `name`, `constructor` and optionally
`init` and `shutdown`. The script instance will be exported as
`Script.name`, and if the parent module is main, it will be executed.

    exports.register = (targetModule, scriptTypeOrDefinition) ->
        if not issubclass scriptTypeOrDefinition, exports.Script
            scriptTypeOrDefinition = exports.create scriptTypeOrDefinition
        instance = new scriptTypeOrDefinition
        targetModule.exports[instance.name] = instance
        if targetModule == require.main
            instance.main()

    exports.create = (scriptDefinition) ->
        assert scriptDefinition.name?,
            "Script definition must have a name"
        assert scriptDefinition.constructor?,
            "Script definition must have a constructor"

        {name, constructor, init, shutdown} =
            scriptDefinition

        class NewScript extends exports.Script

            @property 'name', ->
                name

            constructor: ->
                super
                try
                    Control::setRegistry bind @add, @
                    constructor.apply @, arguments
                finally
                    Control::setRegistry null
                this

            init: ->
                @preinit?.apply @, arguments
                super
                init?.apply @, arguments

            shutdown: ->
                shutdown?.apply @, arguments
                super
                @postshutdown?.apply @, arguments

        special = ['name', 'constructor', 'init', 'shutdown']
        for k, v of scriptDefinition
            if k not in special
                NewScript::[k] = v

        NewScript


Then, inherit from the **Script** class to define your own controller
mappings. These scripts can be used to both generate de XML
configuration file for Mixxx and also as the script itself, when
properly compiled to Javascript.

To work properly, the script file name must the the same as the class
name but in lowercase, and it must be registered using the
**register** function -- i.e. if you have a script called
`MyGreatController`, it should be in a file called
`mygreatcontroller.litcoffee`, and this file should contain a line
like:

>    script.register module, MyGreatController

The `module` variable is [defined automatically by *node.js*](
http://nodejs.org/api/modules.html#modules_the_module_object), you do
not have to care about it.

    class exports.Script

### Properties

This is the metadata that is displayed in the Mixx preferences
panel. Overide it with your details.

        info:
            name: "[mixco] Generic Script"
            author: "Juan Pedro Bolivar Puente <raskolnikov@gnu.org>"
            description: ""
            forums: ""
            wiki: ""


The **name** property returns the most derived class name *in
lowercase*, which is how the script instance is registered in the
target module, and how the script file should be called.

        @property 'name',
            configurable: true
            get: ->
                @constructor.name.toLowerCase()

Use **add** to add controls to your script instance.

        add: (controls...) ->
            assert not @_isInit, "Can only add controls in constructor"
            @controls.push flatten(controls)...

### Mixxx protocol

These methos are called by Mixxx when the script is loaded or
unloaded.

        init: catching ->
            @_isInit = true
            for control in @controls
                control.init this

        shutdown: catching ->
            for control in @controls
                control.shutdown this
            delete @_isInit

### Constructor

        constructor: ->
            @controls = []

### Mixxx environment

In general, controls, behaviours and other entities using the Mixxx
environment --the global variables like *engine* or *midi*-- should
access it via this property instead.  This improves testability.

        mixxx:
            engine: engine if engine?
            midi:   midi   if midi?
            script: script if script?

### Standalone execution

The following methods are executed implicitly by **register** when the
script is executed as a standalone application.  It can generate the
XML file and display some help.

        main: ->
            for arg in process.argv
                if arg in ['-h', '--help']
                    console.info @help()
                    break
                if arg in ['-g', '--generate-config']
                    console.info @config()
                    break

        help: ->
            """
            Mixxx Controller Script
            =======================

            Name: #{@info.name}
            Author: #{@info.author}
            Description: #{@info.description}
            Forums: #{@info.description}

            Usage
            -----
            1. Generate Mixxx config:
                coffee #{@name}.coffee -g > #{@name}.xml

            2. Generate Mixxx script:
                coffee -c #{@name}.coffee
            """

        config: ->
            """
            <?xml version='1.0' encoding='utf-8'?>
            <MixxxControllerPreset mixxxVersion=\"1.11.0+\" schemaVersion=\"1\">
            #{indent 1}<info>
            #{indent 2}<name>#{xmlEscape(@info.name)}</name>
            #{indent 2}<author>#{xmlEscape(@info.author)}</author>
            #{indent 2}<description>#{xmlEscape(@info.description)}</description>
            #{indent 2}<wiki>#{xmlEscape(@info.wiki)}</wiki>
            #{indent 2}<forums>#{xmlEscape(@info.forums)}</forums>
            #{indent 1}</info>
            #{indent 1}<controller id=\"#{@name}\">
            #{indent 2}<scriptfiles>
            #{indent 3}<file functionprefix=\"#{@name}\"
            #{indent 3}      filename=\"#{@name}.js\"/>
            #{indent 2}</scriptfiles>
            #{indent 2}<controls>
            #{@configInputs 3}
            #{indent 2}</controls>
            #{indent 2}<outputs>
            #{@configOutputs 3}
            #{indent 2}</outputs>
            #{indent 1}</controller>
            </MixxxControllerPreset>
            """

### Implementationd details

        configInputs: (depth) ->
            (control.configInputs depth, this for control in @controls)
                .filter((x) -> x)
                .join('\n')

        configOutputs: (depth) ->
            (control.configOutputs depth, this for control in @controls)
                .filter((x) -> x)
                .join('\n')

The **registerHandler** method is called during initialization by the
controls to register a handler callback in the script.  If `id` is not
passed, one is generated for them. When `id` is passed, the handler
key is constant and can be queried even before registering the
handler, using the **handlerKey** method.  Otherwise, the handler can
still be known from the return value of `registerHandler`.

        _nextCallbackId: 1
        registerHandler: (callback, id=undefined) ->
            id or= @_nextCallbackId++
            handlerName = "__handle_#{id}"
            assert not this[handlerName],
                   "Handlers can be registered only once (#{handlerName})"

            this[handlerName] = callback
            return @handlerKey id

        handlerKey: (id=undefined) ->
            if not id?
                id = @_nextCallbackId - 1
            "#{@name}.__handle_#{id}"


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
