mixco.transform
===============

Methods to transform MIDI values to Mixxx control values.

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


Utilities
---------

    binary   = (v) -> if v > 0 then 1 else 0
    linear   = (v, min, max) -> min + v * (max - min)
    centered = (v, min, center, max) ->
        if v < .5
            linear v*2, min, center
        else
            linear (v-.5)*2, center, max

    transform = (f, args...) -> (v) -> f v / 127.0, args...

    binaryT   = transform binary
    linearT   = -> transform linear, arguments...
    centeredT = -> transform centered, arguments...
    defaultT  = linearT 0.0, 1.0

    exports.binaryT = binaryT
    exports.linearT = linearT
    exports.ceneredT = centeredT
    exports.defaultT = defaultT

Mappings
--------

The **mappings** table defines a set of functions that convert a MIDI
value to the value ranges that Mixxx controls expect.  Extend as
needed. Please make sure to keep it in sync with the official
[Mixxx controls documentation][mixxxcontrols].

  [mixxxcontrols]: http://www.mixxx.org/wiki/doku.php/mixxxcontrols

    exports.mappings =
        loop_halve:             binaryT
        loop_double:            binaryT
        back:                   binaryT
        balance:                linearT -1.0, 1.0
        beatloop_16_activate:   binaryT
        beatloop_16_toggle:     binaryT
        beatloop_1_activate:    binaryT
        beatloop_1_toggle:      binaryT
        beatloop_2_activate:    binaryT
        beatloop_2_toggle:      binaryT
        beatloop_32_activate:   binaryT
        beatloop_32_toggle:     binaryT
        beatloop_4_activate:    binaryT
        beatloop_4_toggle:      binaryT
        beatloop_8_activate:    binaryT
        beatloop_8_toggle:      binaryT
        beatloop_dobule:        binaryT
        beatloop_halve:         binaryT
        beats_translate_curpos: binaryT
        beatsync:               binaryT
        beatsync_tempo:         binaryT
        crossfader:             linearT -1.0, 1.0
        cue_default:            binaryT
        filterHigh:             centeredT 0.0, 1.0, 4.0
        filterLow:              centeredT 0.0, 1.0, 4.0
        filterMid:              centeredT 0.0, 1.0, 4.0
        fwd:                    binaryT
        headMix:                centeredT -1.0, 1.0
        headVolume:             centeredT 0.0, 1.0, 5.0
        hotcue_1_activate:      binaryT
        hotcue_1_clear:         binaryT
        hotcue_2_activate:      binaryT
        hotcue_2_clear:         binaryT
        hotcue_3_activate:      binaryT
        hotcue_3_clear:         binaryT
        hotcue_4_activate:      binaryT
        hotcue_4_clear:         binaryT
        hotcue_5_activate:      binaryT
        hotcue_5_clear:         binaryT
        hotcue_6_activate:      binaryT
        hotcue_6_clear:         binaryT
        hotcue_7_activate:      binaryT
        hotcue_7_clear:         binaryT
        wheel:                  linearT -3.0, 3.0
        jog:                    linearT -3.0, 3.0
        LoadSelectedTrack:      binaryT
        play:                   binaryT
        plf:                    binaryT
        pregain:                centeredT 0.0, 1.0, 4.0
        rate:                   linearT -1.0, 1.0
        rate_temp_down:         binaryT
        rate_temp_down_small:   binaryT
        rate_temp_up:           binaryT
        rate_temp_up_small:     binaryT
        SelectNextPlaylist:     binaryT
        SelectNextTrack:        binaryT
        SelectPrevPlaylist:     binaryT
        SelectPrevTrack:        binaryT
        volume:                 defaultT
