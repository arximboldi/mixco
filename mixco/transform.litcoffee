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
        "beatloop_0.0625_activate":     binaryT
        "beatloop_0.0625_toggle":       binaryT
        "beatloop_0.125_activate":      binaryT
        "beatloop_0.125_toggle":        binaryT
        "beatloop_0.5_activate":        binaryT
        "beatloop_0.5_toggle":          binaryT
        "beatlooproll_0.0625_activate": momentaryT
        "beatlooproll_0.125_activate":  momentaryT
        "beatlooproll_0.5_activate":    momentaryT
        back:                           momentaryT
        balance:                        linearT -1.0, 1.0
        beatloop_16_activate:           binaryT
        beatloop_16_toggle:             binaryT
        beatloop_1_activate:            binaryT
        beatloop_1_toggle:              binaryT
        beatloop_2_activate:            binaryT
        beatloop_2_toggle:              binaryT
        beatloop_32_activate:           binaryT
        beatloop_32_toggle:             binaryT
        beatloop_4_activate:            binaryT
        beatloop_4_toggle:              binaryT
        beatloop_8_activate:            binaryT
        beatloop_8_toggle:              binaryT
        beatlooproll_16_activate:       binaryT
        beatlooproll_1_activate:        binaryT
        beatlooproll_2_activate:        binaryT
        beatlooproll_32_activate:       binaryT
        beatlooproll_4_activate:        binaryT
        beatlooproll_8_activate:        binaryT
        beatloop_double:                binaryT
        beatloop_halve:                 binaryT
        beats_translate_curpos:         binaryT
        beatsync:                       binaryT
        beatsync_tempo:                 binaryT
        crossfader:                     linearT -1.0, 1.0
        cue_default:                    binaryT
        eject:                          binaryT
        filterHigh:                     centeredT 0.0, 1.0, 4.0
        filterHighKill:                 binaryT
        filterLow:                      centeredT 0.0, 1.0, 4.0
        filterLowKill:                  binaryT
        filterMid:                      centeredT 0.0, 1.0, 4.0
        filterMidKill:                  binaryT
        fwd:                            momentaryT
        headMix:                        centeredT -1.0, 1.0
        headVolume:                     centeredT 0.0, 1.0, 5.0
        hotcue_1_activate:              binaryT
        hotcue_1_clear:                 binaryT
        hotcue_2_activate:              binaryT
        hotcue_2_clear:                 binaryT
        hotcue_3_activate:              binaryT
        hotcue_3_clear:                 binaryT
        hotcue_4_activate:              binaryT
        hotcue_4_clear:                 binaryT
        hotcue_5_activate:              binaryT
        hotcue_5_clear:                 binaryT
        hotcue_6_activate:              binaryT
        hotcue_6_clear:                 binaryT
        hotcue_7_activate:              binaryT
        hotcue_7_clear:                 binaryT
        jog:                            identityT
        keylock:                        binaryT
        lfoDelay:                       linearT 50.0, 10000.0
        lfoDepth:                       defaultT
        lfoPeriod:                      linearT 50000.0, 2000000.0
        LoadSelectedTrack:              binaryT
        loop_double:                    binaryT
        loop_enabled:                   binaryT
        loop_end_position:              linearT
        loop_halve:                     binaryT
        loop_in:                        binaryT
        loop_out:                       binaryT
        loop_start_position:            linearT
        play:                           binaryT
        playposition:                   linearT 0.0, 1.0
        plf:                            binaryT
        pregain:                        centeredT 0.0, 1.0, 4.0
        pregain_toggle:                 binaryT
        rate:                           linearT -1.0, 1.0
        rate_temp_down:                 binaryT
        rate_temp_down_small:           binaryT
        rate_temp_up:                   binaryT
        rate_temp_up_small:             binaryT
        reverse:                        binaryT
        scratch2:                       linearT -3.0, 3.0
        scratch2_enable:                binaryT
        SelectNextPlaylist:             binaryT
        SelectNextTrack:                binaryT
        SelectPrevPlaylist:             binaryT
        SelectPrevTrack:                binaryT
        SelectTrackKnob:                identityT
        slip_enabled:                   binaryT
        talkover:                       binaryT
        ToggleSelectedSidebarItem:      binaryT
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
