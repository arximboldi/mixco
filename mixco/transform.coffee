#
#  File:       core.coffee
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#  Date:       Mon May 23 18:46:12 2013
#
#  Scripting default transformation mappings, as defined in:
#
#      http://mixxx.org/wiki/doku.php/mixxxcontrols
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


linear = (v, min, max) -> min + v * (max - min)
centered = (v, min, center, max) ->
    if v < .5 then linear v*2, min, center else linear (v-.5)*2, center, max

transform = (f, args...) -> (v) -> f v / 127.0, args...
linearT = -> transform linear, arguments...
centeredT = -> transform centered, arguments...
defaultT = linearT 0.0, 1.0

mappings =
    ###
    Set of functions that convert a MIDI value to the value ranges
    that Mixxx controls expect.
    ###
    rate:       linearT -1.0, 1.0
    volume:     defaultT
    filterLow:  centeredT 0.0, 1.0, 4.0
    filterMid:  centeredT 0.0, 1.0, 4.0
    filterHigh: centeredT 0.0, 1.0, 4.0
    pregain:    centeredT 0.0, 1.0, 4.0


exports.mappings = mappings
