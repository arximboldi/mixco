#
#  File:       core.coffee
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#  Date:       Mon May 20 16:23:45 2013
#  Time-stamp: <2013-05-20 19:21:12 raskolnikov>
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

    init: ->
        null

    shutdown: ->
        null

    escape: (str) ->
        str
            .replace('&', '&amp;')
            .replace('"', '&quot;')
            .replace('>', '&gt;')
            .replace('<', '&lt;')

    config: ->
        """
        <?xml version='1.0' encoding='utf-8'?>
        <MixxxControllerPreset mixxxVersion=\"1.11.0+\" schemaVersion=\"1\">
            <info>
                <name>#{@escape(@info.name)}</name>
                <author>#{@escape(@info.author)}</author>
                <description>#{@escape(@info.description)}</description>
                <wiki>#{@escape(@info.wiki)}</wiki>
                <forums>#{@escape(@info.forums)}</forums>
            </info>
            <controller id=\"#{@codename}\">
                <scriptfiles>
                    <file functionprefix=\"#{@codename.toLowerCase()}\"
                          filename=\"#{@codename.toLowerCase()}.js\"/>
                </scriptfiles>
                <controls>
                </controls>
            </controller>
        </MixxxControllerPreset>
        """

exports.Script = Script
