mixco.transform
===============

Methods to transform MIDI values to Mixxx control values.

Utilities
---------

    exports.identity          = (v)       -> v
    exports.identity.inverse  = exports.identity
    exports.momentary         = (v)       -> if v > 0 then 1 else 0
    exports.momentary.inverse = (v)       -> if v > 0 then 1 else 0
    exports.binary            = (v, oldv) -> if v > 0 then not oldv else null
    exports.binary.inverse    = (v)       -> if v > 0 then 1 else 0
    exports.linear            = (v, min, max) -> min + v * (max - min)
    exports.linear.inverse    = (v, min, max) -> (v - min) / (max - min)
    exports.centered          = (v, min, center, max) ->
        if v < .5
        then linear v*2, min, center
        else linear (v-.5)*2, center, max
    exports.centered.inverse  = (v, min, center, max) ->
        if v < center
        then 0.5 * linear.inverse v, min, center
        else 0.5 + 0.5 * linear.inverse v, center, max

    transform = (f, args...) ->
        result         = (v, oldv) -> f v / 127.0, args..., oldv
        result.inverse = (v)       -> 127 * f.inverse(v, args...)
        result

    exports.identityT  = identityT  = exports.identity
    exports.momentaryT = momentaryT = transform exports.momentary
    exports.binaryT    = binaryT    = transform exports.binary
    exports.linearT    = linearT    = -> transform exports.linear, arguments...
    exports.centeredT  = centeredT  = -> transform exports.centered, arguments...
    exports.defaultT   = defaultT   = linearT 0.0, 1.0

Mappings
--------

The **mappings** table defines a set of functions that convert a MIDI
value to the value ranges that Mixxx controls expect.  Extend as
needed. Please make sure to keep it in sync with the official
[Mixxx controls documentation][mixxxcontrols].

  [mixxxcontrols]: http://www.mixxx.org/wiki/doku.php/mixxxcontrols

    exports.mappings =
        "beatloop_0.0625_activate":     momentaryT
        "beatloop_0.0625_toggle":       momentaryT
        "beatloop_0.125_activate":      momentaryT
        "beatloop_0.125_toggle":        momentaryT
        "beatloop_0.5_activate":        momentaryT
        "beatloop_0.5_toggle":          momentaryT
        "beatlooproll_0.0625_activate": momentaryT
        "beatlooproll_0.125_activate":  momentaryT
        "beatlooproll_0.5_activate":    momentaryT
        back:                           momentaryT
        balance:                        linearT -1.0, 1.0
        beatloop_16_activate:           momentaryT
        beatloop_16_toggle:             momentaryT
        beatloop_1_activate:            momentaryT
        beatloop_1_toggle:              momentaryT
        beatloop_2_activate:            momentaryT
        beatloop_2_toggle:              momentaryT
        beatloop_32_activate:           momentaryT
        beatloop_32_toggle:             momentaryT
        beatloop_4_activate:            momentaryT
        beatloop_4_toggle:              momentaryT
        beatloop_8_activate:            momentaryT
        beatloop_8_toggle:              momentaryT
        beatlooproll_16_activate:       momentaryT
        beatlooproll_1_activate:        momentaryT
        beatlooproll_2_activate:        momentaryT
        beatlooproll_32_activate:       momentaryT
        beatlooproll_4_activate:        momentaryT
        beatlooproll_8_activate:        momentaryT
        beatloop_double:                momentaryT
        beatloop_halve:                 momentaryT
        beats_translate_curpos:         momentaryT
        beatsync:                       momentaryT
        beatsync_tempo:                 momentaryT
        crossfader:                     linearT -1.0, 1.0
        cue_default:                    momentaryT
        eject:                          momentaryT
        filterHigh:                     centeredT 0.0, 1.0, 4.0
        filterHighKill:                 binaryT
        filterLow:                      centeredT 0.0, 1.0, 4.0
        filterLowKill:                  binaryT
        filterMid:                      centeredT 0.0, 1.0, 4.0
        filterMidKill:                  binaryT
        fwd:                            momentaryT
        headMix:                        centeredT -1.0, 1.0
        headVolume:                     centeredT 0.0, 1.0, 5.0
        hotcue_1_activate:              momentaryT
        hotcue_1_clear:                 momentaryT
        hotcue_2_activate:              momentaryT
        hotcue_2_clear:                 momentaryT
        hotcue_3_activate:              momentaryT
        hotcue_3_clear:                 momentaryT
        hotcue_4_activate:              momentaryT
        hotcue_4_clear:                 momentaryT
        hotcue_5_activate:              momentaryT
        hotcue_5_clear:                 momentaryT
        hotcue_6_activate:              momentaryT
        hotcue_6_clear:                 momentaryT
        hotcue_7_activate:              momentaryT
        hotcue_7_clear:                 momentaryT
        jog:                            identityT
        keylock:                        binaryT
        lfoDelay:                       linearT 50.0, 10000.0
        lfoDepth:                       defaultT
        lfoPeriod:                      linearT 50000.0, 2000000.0
        LoadSelectedTrack:              momentaryT
        loop_double:                    momentaryT
        loop_enabled:                   binaryT
        loop_end_position:              linearT
        loop_halve:                     momentaryT
        loop_in:                        momentaryT
        loop_out:                       momentaryT
        loop_start_position:            linearT
        play:                           binaryT
        playposition:                   linearT 0.0, 1.0
        plf:                            binaryT
        pregain:                        centeredT 0.0, 1.0, 4.0
        pregain_toggle:                 binaryT
        rate:                           linearT -1.0, 1.0
        rate_temp_down:                 momentaryT
        rate_temp_down_small:           momentaryT
        rate_temp_up:                   momentaryT
        rate_temp_up_small:             momentaryT
        reverse:                        binaryT
        scratch2:                       linearT -3.0, 3.0
        scratch2_enable:                binaryT
        SelectNextPlaylist:             momentaryT
        SelectNextTrack:                momentaryT
        SelectPrevPlaylist:             momentaryT
        SelectPrevTrack:                momentaryT
        SelectTrackKnob:                identityT
        slip_enabled:                   binaryT
        talkover:                       binaryT
        ToggleSelectedSidebarItem:      momentaryT
        volume:                         defaultT
        VuMeter:                        defaultT
        VuMeterL:                       defaultT
        VuMeterR:                       defaultT
        wheel:                          linearT -3.0, 3.0

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
