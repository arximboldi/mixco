mixco.script
============

Main interface for defining custom Mixx scripts.

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


Dependencies
------------

    util = require('./util')
    indent = util.indent
    xmlEscape = util.xmlEscape
    catching = util.catching


Utilities
---------

The **event** function returns an object representing an script event
coming from Mixxx.

    event = (channel, control, value, status, group) ->
        channel: channel
        control: control
        value: value
        status: status
        group: group


Script
------

The *register* function registers a instance of the class `scriptType`
instance into the parent module.  The script instance will be exported
as `Script.name`, and if the parent module is main, it will be
executed.

    exports.register = (targetModule, scriptType) ->
        instance = new scriptType
        targetModule.exports[instance.name] = instance
        if targetModule == require.main
            instance.main()


Inherit from the **Script** class to define your own controller mappings.

These scripts can be used to both generate de XML configuration
file for Mixxx and also as the script itself, when properly
compiled to Javascript.

To work properly, the script name must the the same as the class
name but in lowercase, and it must be registered using the
**register** function.


    class exports.Script

### Properties

This is the metadata that is displayed in the Mixx preferences
panel. Overide it with your details.

        info:
            name: "[MixCo] Generic Script"
            author: "Juan Pedro Bolivar Puente <raskolnikov@gnu.org>"
            description: ""
            forums: ""
            wiki: ""


The **name** property returns the most derived class name *in
lowercase*, which is how the script instance is registered in the
target module, and how the script file should be called.

        @property 'name',
            get: ->
                @constructor.name.toLowerCase()

Use **add** to add controls to your script instance.

        add: (controls...) ->
            @controls.push controls...

### Mixxx protocol

        init: catching ->
            for control in @controls
                control.init this

        shutdown: catching ->
            for control in @controls
                control.shutdown this

### Constructor

        constructor: ->
            @controls = []


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
            #{indent 1}<controller id=\"#{@codename}\">
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

        scriptedKey: (id) ->
            "#{@name}._handle#{id}"


This method is called during initialization by the controls to
register a handler callback in the script.

        registerScripted: (control, id) ->
            this["_handle#{id}"] = (args...) -> control.onScript(event args...)
            this
