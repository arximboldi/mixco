script.xponent
==============

Mixxx script file for the **M-Audio Xponent** controller.  The script
is based on the [**Mixco** framework](../index.html).  The numbers in
the following picture will be used in the script to describe the
functionallity of the controls.

  ![Xponent Layout](../pic/xponent.png)

    {assert}  = require '../mixco/util'
    script    = require '../mixco/script'
    control   = require '../mixco/control'
    behaviour = require '../mixco/behaviour'
    value     = require '../mixco/value'
    transform = require '../mixco/transform'

    script.register module, class Xponent extends script.Script

        info:
            name: '[mixco] M-Audio Xponent'
            author: 'Juan Pedro Bolivar Puente <raskolnikov@gnu.org>'
            description:
                """
                Controller mapping for the M-Audio Xponent DJ controller.
                """
            forums: ''
            wiki: ''

        c = control
        b = behaviour
        v = value
        t = transform

Global section
--------------

Controls that do not have a per-deck functionality.

        constructor: ->
            super
            ccId = (cc) -> c.ccIds cc, 2
            g  = "[Master]"

* **27.** Pre-hear mix.

            @add c.knob(ccId 0x0D).does g, "headMix"

* **39.** Crossfader.

            @add c.slider(ccId 0x07).does g, "crossfader"

Per deck controls
-----------------

We add the two decks with the `addDeck(idx)` function. In the
*Xponent*, each MIDI message is repeated per-deck on a different
channel.

            @decks = b.chooser "pfl"
            @addDeck 0
            @addDeck 1

        addDeck: (i) ->
            assert i in [0, 1]
            g  = "[Channel#{i+1}]"
            ccId = (cc) -> c.ccIds cc, i
            noteId = (note) -> c.noteIds note, i
            noteOnId = (note) -> c.noteOnIds note, i

* **15.** Shift. It changes the behaviour of some controls.  Note
  that there is a shift button per-deck, which only affects the
  controls of that deck.

            shift = do b.modifier
            @add c.ledButton(noteId 0x2C).does shift

* **12.** Pre-Fade Listen. Select which deck goes to the pre-hear.

            @add c.ledButton(noteOnId 0x14).does @decks.choose(i)

### The mixer


* **20.** Filter and gain kills.

            @add c.ledButton(noteId 0x08).does g, "filterLowKill"
            @add c.ledButton(noteId 0x09).does g, "filterMidKill"
            @add c.ledButton(noteId 0x0A).does g, "filterHighKill"
            @add c.ledButton(noteId 0x0B).does g, "pregain_toggle"

* **22.** Mixer EQ and gain.

            @add c.knob(ccId 0x08).does g, "filterLow"
            @add c.knob(ccId 0x09).does g, "filterMid"
            @add c.knob(ccId 0x0A).does g, "filterHigh"
            @add c.knob(ccId 0x0B).does b.soft g, "pregain"

* **23.** Per deck volume meters.

            @add c.meter(c.ccIds 0x12+i, 3).does b.map(g, "VuMeter").meter()

* **34.** Sync button. Adjust pitch and aligns grids to beatmatch both
  tracks. When *shift* is pressed, it only adjusts pitch, not phase.

            @add c.ledButton(noteId 0x02)
                .when(shift, g, "beatsync_tempo")
                .else g, "beatsync"

* **33.** Deck volume.

            @add c.slider(ccId 0x07).does g, "volume"

* **38.** Punch-in/transform. While pressed, lets this track be heard
  overriding the corssfader.

            @add c.ledButton(noteId 0x07).does b.punchIn (0.5-i)

### The transport section

* **29.** Song progress indication. When it approches the end of the
  playing song it starts blinking.

            playpositionMeter = do ->
                step = 0
                (pos) ->
                    engine = @script.mixxx.engine
                    duration = switch
                        when not engine.getValue g, "play" then undefined
                        when pos > .9  then 5
                        when pos > .8  then 9
                        when pos > .75 then 13
                        else undefined
                    if duration?
                        step = (step + 1) % duration
                        if step > duration / 2 then 0 else pos * 127
                    else
                        step = 0
                        pos * 127

            @add c.meter(c.ccIds 0x14+i, 3).does b.mapout(g, "playposition")
                .meter playpositionMeter

* **30.** Back and forward.

            @add c.ledButton(noteId 0x21).does g, "back"
            @add c.ledButton(noteId 0x22).does g, "fwd"

* **31.** Includes several buttons...

- The top buttons with numbers are the *hotcues*. On first press,
  sets the hotcue. On second press, jumps to hotcue. When *shift* is
  held, deletes the hotcue point.

            for idx in [0..4]
                @add c.ledButton(noteId(0x17 + idx))
                    .when(shift, g, "hotcue_#{idx+1}_clear", g, "hotcue_#{idx+1}_enabled")
                    .else g, "hotcue_#{idx+1}_activate", g, "hotcue_#{idx+1}_enabled"

- The little arrow buttons do *beatjump* -- jump forward or back by
  one beat. When *shift* is pressed, they select the previous or
  next item of the browser sidebar.

            @add c.ledButton(noteId 0x1C)
                .when(shift, "[Playlist]", "SelectPrevPlaylist")
                .else b.beatJump g, -1
            @add c.ledButton(noteId 0x1D)
                .when(shift, "[Playlist]", "SelectNextPlaylist")
                .else b.beatJump g, 1

- The *lock* button does *key lock* -- i.e. makes tempo changes
  independent of pitch. When *shift* is pressed, it expands/collapses
  the selected browser item.

            @add c.ledButton(noteOnId 0x1E)
                .when(shift, "[Playlist]", "ToggleSelectedSidebarItem")
                .else g, "keylock"

- The *plus* (+) button moves the beat grid to align with the current
  play position.

            @add c.ledButton(noteId 0x1F).does g, "beats_translate_curpos"

- The *minus* (-) button plays the track in reverese.

            @add c.ledButton(noteId 0x20).does g, "reverse"

* **35.** Cue button.

            @add c.ledButton(noteId 0x23).does g, "cue_default"

* **37.** Play/pause button.

            @add c.ledButton(noteOnId 0x24).does g, "play"


### The looping section

* **36.** This includes several controls to manage loops...

- The *in* and *out* buttons set the loop start and end to the
  current playing position.  When *shift* is pressed, they halve and
  double the current loop size respectively.

            @add c.ledButton(noteId 0x29)
                .when(shift, g, "loop_halve")
                .else g, "loop_in"
            @add c.ledButton(noteId 0x2B)
                .when(shift, g, "loop_double")
                .else g, "loop_out"


- The *loop* toggles the current loop on/off whenever there is a loop
  selected.

            @add c.ledButton(noteId 0x2A).does g, "reloop_exit", g, "loop_enabled"

- The numbers set and trigger a loop of 4, 8, 16 and 32 beats
  respectively. When *shift*, they set loops of 1/8, 1/2, 1 or 2
  long.

            @add c.ledButton(noteId 0x25)
                .when(shift, g, "beatloop_0.125_activate", g, "beatloop_0.125_enabled")
                .else g, "beatloop_4_activate", g, "beatloop_4_enabled"
            @add c.ledButton(noteId 0x26)
                .when(shift, g, "beatloop_0.5_activate", g, "beatloop_0.5_enabled")
                .else g, "beatloop_8_activate", g, "beatloop_8_enabled"
            @add c.ledButton(noteId 0x27)
                .when(shift, g, "beatloop_1_activate", g, "beatloop_1_enabled")
                .else g, "beatloop_16_activate", g, "beatloop_16_enabled"
            @add c.ledButton(noteId 0x28)
                .when(shift, g, "beatloop_2_activate", g, "beatloop_2_enabled")
                .else g, "beatloop_32_activate", g, "beatloop_32_enabled"

### The wheel and pitch section

* **10.** Toggles *scratch* mode.

            scratchMode = do b.option
            @add c.ledButton(noteOnId 0x15).does scratchMode

* **11.** The wheel does different functions...

  - When the deck is stopped, it moves the play position.

  - When *scrach* mode is on, it will stop the song when touched on
  top and control the track play like a vinyl when moved.

  - Otherwise, it can be used to *nudge* the playing speed up or down
  to synch the phase of tracks when the track is playing.

  - When *shift* is pressed, it will scroll through the current list
  of tracks in the browser.

            selectTrackKnobTransform = do ->
                toggle = false
                (val) ->
                    val = val - 64
                    toggle = not toggle or Math.abs(val) > 16
                    if toggle then val.sign() else null

            @add c.ledButton(noteId 0x16)
                .when v.and(v.not(shift), scratchMode), b.scratchEnable i+1
            @add c.knob(ccId 0x16)
                .when(shift, b.map("[Playlist]", "SelectTrackKnob")
                    .transform selectTrackKnobTransform)
                .else.when(scratchMode, b.scratchTick i+1, (v) -> v-64)
                .else b.map(g, "jog").transform (v) -> (v-64)/8.0

* **26.** Temporarily nudges the pitch down or up. When **shift**,
they do it in a smaller ammount.

            @add c.ledButton(noteId 0x10)
                .when(shift, g, "rate_temp_down_small")
                .else g, "rate_temp_down"
            @add c.ledButton(noteId 0x11)
                .when(shift, g, "rate_temp_up_small")
                .else g, "rate_temp_up"

* **32.** Pitch slider, adjusts playing speed.

            @add c.slider(c.pbIds i).does b.soft g, "rate"

* **21.** Custom effects that include...

- The *big cross* (X) button simulates a *brake* effect as if the
  turntable was turned off suddenly. On *shift*, it ejects the track
  from the deck.

            @add c.ledButton(noteId 0x12)
                .when(shift, g, "eject")
                .else b.brake i+1

- The *big minus* (--) button simulates a *backspin* effect as if the
  vinyl was launched backwards. On *shift*, it loads the selected
  track in the browser into the deck.

            @add c.ledButton(noteId 0x13)
                .when(shift, g, "LoadSelectedTrack")
                .else b.spinback i+1

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
