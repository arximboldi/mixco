#
#  File:       nanokontrol2.coffee
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#  Date:       Mon May 20 15:27:56 2013
#
#  Mixxx script file for the NanoKontrol2
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

    config: ->
        """
        <?xml version='1.0' encoding='utf-8'?>
        <MixxxControllerPreset mixxxVersion=\"1.11.0+\" schemaVersion=\"1\">
            <info>
                <name>#{@info.name}</name>
                <author>#{@info.author}</author>
                <description>#{@info.description}</description>
                <wiki>#{@info.wiki}</wiki>
                <forums>#{@info.forums}</forums>
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


class NanoKontrol2 extends Script
    codename: 'NanoKontrol2'
    info:
        name: 'Korg Nanokontrol 2'
        author: 'Juan Pedro Bolivar Puente <raskolnikov@gnu.org>'
        description:
            """
            Controller mapping for Korg Nanokontrol 2 that is
            targetted at being used as main interface for Mixxx.
            """
        forums: 'Not yet'
        wiki: 'Not yet'


root = exports ? this
root.nanokontrol2 = new NanoKontrol2
root.nanokontrol2.main()
