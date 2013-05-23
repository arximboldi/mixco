#
#  File:       core.coffee
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#  Date:       Mon May 20 16:23:45 2013
#
#  Scripting engine basic class.
#

#
#  Copyright (C) 2013 Juan Pedro Bolívar Puente
#
#  This program is free software: you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

util = require('./util')
indent = util.indent
xmlEscape = util.xmlEscape
catching = util.catching


event = (channel, control, value, status, group) ->
    channel: channel
    control: control
    value: value
    status: status
    group: group


class Script

    info:
        name: "Generic Mixxx Controller script"
        author: "Juan Pedro Bolivar Puente"
        description: ""
        forums: ""
        wiki: ""

    @property 'name'
        get: -> @constructor.name.toLowerCase()

    constructor: ->
        @controls = []

    add: (controls...) ->
        @controls.push controls...

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

    init: catching ->
        for control in @controls
            control.init this

    shutdown: catching ->
        for control in @controls
            control.shutdown this

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

    registerScripted: (control, id) ->
        this["_handle#{id}"] = (args...) -> control.onScript(event args...)
        this


exports.Script = Script

