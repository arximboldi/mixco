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


printer = (args...) ->
    try
        print args.toString()
    catch _
        console.error args.toString()


Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc


catching = (f) -> ->
    try
        f.apply @, arguments
    catch err
        printer "ERROR: #{err}"


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


midi = (midino = 0, channel = 0) ->
    midino: midino
    channel: channel
    status: (message) -> (message << 4) | @channel
    configMidi: (message, depth) ->
        """
        #{indent depth}<status>#{hexStr @status(message)}</status>
        #{indent depth}<midino>#{hexStr @midino}</midino>
        """

class Control

    constructor: (@id=midi(), @group="[Channel1]", @key=null) ->
        if not (@id instanceof Object)
            @id = midi @id

    init: (script) ->

    shutdown: (script) ->

    configInputs: (depth) ->
        """
        #{indent depth}<control>
        #{indent depth+1}<group>#{@group}</group>
        #{indent depth+1}<key>#{@key}</key>
        #{@id.configMidi @message, depth+1}
        #{indent depth+1}<options>
        #{@configOptions depth+2}
        #{indent depth+1}</options>
        #{indent depth}</control>
        """

    configOptions: (depth) ->
        "#{indent depth}<normal/>"

    configOutputs: (depth) -> ""


class Knob extends Control

    message: MIDI_CC


class Button extends Control

    message: MIDI_CC

    configOptions: (depth) ->
        "#{indent depth}<button/>"


class LedButton extends Button

    onValue: 0x7f
    offValue: 0x00

    configOutputs: (depth) ->
        """
        #{indent depth}<output>
        #{indent depth+1}<group>#{@group}</group>
        #{indent depth+1}<key>#{@key}</key>
        #{@id.configMidi @message, depth+1}
        #{indent depth+1}<on>#{hexStr @onValue}</on>
		#{indent depth+1}<off>#{hexStr @offValue}</off>
        #{indent depth}<minimum>1</minimum>
        #{indent depth}</output>
        """


Slider = Knob


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
        (control.configInputs depth for control in @controls).join('\n')

    configOutputs: (depth) ->
        (control.configOutputs depth for control in @controls).join('\n')


exports.Script = Script
exports.Knob = Knob
exports.Slider = Slider
exports.Button = Button
exports.LedButton = LedButton

