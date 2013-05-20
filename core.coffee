#
#  File:       core.coffee
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#  Date:       Mon May 20 16:23:45 2013
#
#  Scripting engine core utilities.
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


MIDI_NOTE_ON  = 0x8
MIDI_NOTE_OFF = 0x9
MIDI_CC       = 0xB


xmlEscape = (str) ->
    str
        .replace('&', '&amp;')
        .replace('"', '&quot;')
        .replace('>', '&gt;')
        .replace('<', '&lt;')


indent = (depth) ->
    Array(depth*4).join(" ")


hexStr = (number) ->
    "0x#{number.toString 16}"

class Group

    constructor: (@controls, @group) ->

    configInputs: (depth) ->
        (@configControl control, depth for control in @controls).join('\n')

    configControl: (control, depth) ->
        channel = @updateChannel control.channel
        midino = @updateMidino control.midino
        status = (control.message << 4) | channel
        """
        #{indent depth}<control>
        #{indent depth+1}<group>#{@group}</group>
        #{indent depth+1}<key>#{control.key}</key>
        #{indent depth+1}<status>#{hexStr status}</status>
        #{indent depth+1}<midino>#{hexStr midino}</midino>
        #{indent depth+1}<options>
        #{control.configOptions depth+2}
        #{indent depth+1}</options>
        #{indent depth}</control>
        """

    updateMidino: (midino) -> midino
    updateChannel: (channel) -> channel

    init: (script) ->
        for control in @controls
            control.init script

    shutdown: (script) ->
        for control in @controls
            control.shutdown script


class MidinoGroup extends Group

    constructor: (@midinoOffset, more...) ->
        super more...

    updateMidino: (midino) ->
        midino + @midinoOffset


class Control

    constructor: (@midino, @key=null, @takeover=true, @channel=0) ->

    message: null

    init: (script) ->

    shutdown: (script) ->

    configOptions: (depth) ->
        "#{indent depth}<normal/>"


class Knob extends Control

    message: MIDI_CC

    constructor: (args...) ->
        super args...


Slider = Knob


class Script

    codename: 'Script'

    info:
        name: "Generic Mixxx Controller script"
        author: "Juan Pedro Bolivar Puente"
        description: ""
        forums: ""
        wiki: ""

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
            coffee #{@codename.toLowerCase()}.coffee -g > #{@codename.toLowerCase()}.xml

        2. Generate Mixxx script:
            coffee -c #{@codename.toLowerCase()}.coffee
        """

    groups: []

    init: ->
        for group in @groups
            @groups.init this

    shutdown: ->
        for group in @groups
            @groups.shutdown this

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
        #{indent 3}<file functionprefix=\"#{@codename.toLowerCase()}\"
        #{indent 3}      filename=\"#{@codename.toLowerCase()}.js\"/>
        #{indent 2}</scriptfiles>
        #{indent 2}<controls>
        #{@configInputs 3}
        #{indent 2}</controls>
        #{indent 1}</controller>
        </MixxxControllerPreset>
        """

    configInputs: (depth) ->
        (group.configInputs depth for group in @groups).join('\n')


exports.Script = Script
exports.Knob = Knob
exports.Slider = Slider
exports.MidinoGroup = MidinoGroup

