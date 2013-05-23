#
#  File:       core.coffee
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#  Date:       Mon May 23 18:38:48 2013 
#
#  Scripting engine controls.
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


mangle = (str) ->
    str.replace(' ', '_').replace('[', '__C__').replace(']', '__D__')


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


exports.catching = catching
exports.hexStr = hexStr
exports.indent = indent
exports.xmlEscape = xmlEscape
exports.mangle = mangle

