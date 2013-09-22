script.korg_nanokontrol2
========================

Mixxx script file for the **Korg NanoKontrol2** controller.  The
script is based on the [**Mixco** framework](../index.html).

This script description is a bit more verbose than others, at it tries
to serve as **tutorial** on how to write your own controller scripts.

  ![NanoKontrol2 Layout](../pic/korg_nanokontrol2.jpg)

Dependencies
------------

First, we have to import he *Mixco* modules that we are going to use,
using the [NodeJS,
**require**](http://nodejs.org/api/modules.html#modules_module_require_id)
function.

    {assert}  = require '../mixco/util'
    script    = require '../mixco/script'
    control   = require '../mixco/control'
    behaviour = require '../mixco/behaviour'
    value     = require '../mixco/value'

Also, lets define these couple of shortcuts to save typing.

    c = control
    b = behaviour
    v = value

The script
----------

### Declaration

We define the script with the **script.register** function, which will
create the script instance.  As first parameter we pass the current
module, that is contained in the special *NodeJS* variable
`module`. The second parameter is an object with the actual script.
The `name` attribute is compulsory as should be file name *without
extension*.  It should be a valid JavaScript identifier -- i.e. start
with a letter and contain only alfanumerical characters or underscore.

    script.register module,

        name: 'korg_nanokontrol2'

### Metadata

Then we fill out the metadata. This will be shown to the user in the
preferences window in Mixxx when he selects the script.

        info:
            name: '[mixco] Korg Nanokontrol 2'
            author: 'Juan Pedro Bolivar Puente <raskolnikov@gnu.org>'
            description:
                """
                Controller mapping for Korg Nanokontrol 2 that is
                targetted at being used as main interface for Mixxx.
                """
            forums: ''
            wiki: ''

### Constructor

All the actual interesting stuff happens in the *constructor* of the
script. Here we will create the controls and add them to the script
and define their behaviour.

        constructor: ->

#### Transport section

All the buttons on the left side of the controllers is what we call
the *transport section*. These are global buttons

The *cycle* button will be used as modifier.

            @cycle = b.modifier()
            @add c.ledButton(0x2e).does @cycle

Most of the transport controls will have their behaviour defined
per-deck. We define them here and add the behaviours later.

            @add @backButton      = c.ledButton 0x3a
            @add @fwdButton       = c.ledButton 0x3b
            @add @nudgeDownButton = c.ledButton 0x2b
            @add @nudgeUpButton   = c.ledButton 0x2c

Note that we here abused the expresivity of CoffeeScript, where it can
in many cases omit parentheses. Any of those was equivalent to writting:

>    this.backButton = c.ledButton(0x2b)
>    this.add(this.backButton)

We can browse the playlist too. The load button is added later, per deck.


            @marker = b.modifier()
            @add c.ledButton(0x3C).does @marker

            g = "[Playlist]"
            @add c.ledButton(0x3D)
                .when(@marker, g, "SelectPrevPlaylist")
                .else g, "SelectPrevTrack"
            @add c.ledButton(0x3E)
                .when(@marker, g, "SelectNextPlaylist")
                .else g, "SelectNextTrack"

            @add @loadTrack = c.ledButton(0x2a)

Main play, cue, and sync, lets put them in big buttons.

            @add @sync = c.ledButton(0x29)
            @add @syncTempo = c.ledButton(0x2d)

            g = "[Master]"
            @add c.slider(0x06).does g, "headVolume"
            @add c.slider(0x05).does g, "headMix"
            @add c.slider(0x02).does g, "crossfader"
            @add c.slider(0x01).does b.soft g, "balance"


#### Deck controls

Then, we create a chooser object over the *pfl* (prehear) parameter,
so we will have only one channel with prehear activated at a time.
Also, this will let us change the behaviour of some *transport*
controls depending on which deck is *selected* -- i.e, has prehear
enabled.

            @decks = b.chooser "pfl"

Finally we add the per-deck controls, that are defined in `addDeck`.

            @addDeck 0
            @addDeck 1

        addDeck: (i) ->
            assert i in [0, 1]

            g  = "[Channel#{i+1}]"
            offset = if i == 0 then [3, 2, 1, 0] else [4, 5, 6, 7]

The top 8 knobs are mapped to the two decks mixer filter section (low,
mid, high, gain).

            @add c.knob(0x10 + offset[0]).does g, "filterLow"
            @add c.knob(0x10 + offset[1]).does g, "filterMid"
            @add c.knob(0x10 + offset[2]).does g, "filterHigh"
            @add c.knob(0x10 + offset[3]).does b.soft g, "pregain"

Then the two first "control sections" are mapped like:

  * S: Selects the deck for prehear.
  * M: Cue button for the deck.
  * R: Play button for the deck.
  * The fader controls the volume of the deck.

            @add c.ledButton(0x20 + offset[0]).does @decks.choose i
            @add c.ledButton(0x30 + offset[0]).does g, "cue_default"
            @add c.ledButton(0x40 + offset[0]).does g, "play"
            @add c.slider(0x00 + offset[0]).does g, "volume"

The next two control sections control the pitch related stuff and
effects.

  * S: Bpm tap, also shows the speed.
  * M: Toggles key lock.
  * R: Sets the beat grid to match the current playhead position.
  * The fader controls the pitch of the deck.

            @add c.ledButton(0x20 + offset[3]).does g, "bpm_tap", g, "beat_active"
            @add c.ledButton(0x30 + offset[3]).does g, "keylock"
            @add c.ledButton(0x40 + offset[3]).does g, "beats_translate_curpos"
            @add c.slider(0x00 + offset[3]).does b.soft g, "rate"

The << and >> buttons are a bit more complicated. We want them to
behave as *nudge* buttons for the selected track, but we want the
*cycle* modifier to change the nudge speed. We use the `behaviour.and`
condition combinator to mix the conditions. We also use `control.else.when`
to simplify the negative condition.

            chooseCycle = v.and @cycle, @decks.choose i
            @nudgeUpButton
                .when(chooseCycle, b.toggle 0, 0.5, g, "wheel")
                .else.when @decks.choose(i), b.toggle 0, 0.1, g, "wheel"
            @nudgeDownButton
                .when(chooseCycle, b.toggle 0, -0.5, g, "wheel")
                .else.when @decks.choose(i), b.toggle 0, -0.1, g, "wheel"

Depending on the selected track we map some of the transport buttons.
For example, the *track<* and *track>* buttons control the selected
track *fast forward* and *fast rewind*.

            @fwdButton.when @decks.choose(i), g, "fwd"
            @backButton.when @decks.choose(i), g, "back"

Load the selected track in the selected deck.

            @loadTrack.when @decks.choose(i), g, "LoadSelectedTrack"

Synchronize to the other track.

            @sync.when @decks.choose(i), g, "beatsync"
            @syncTempo.when @decks.choose(i), g, "beatsync_tempo"


Then, we have some looping related buttons in the middle. Also, these
are the hotcue trigger and clear with the *cycle* and *marker*
modifiers.

            @add c.ledButton(0x20 + offset[1])
                .when(@cycle, g, "hotcue_1_activate")
                .else.when(@marker, g, "hotcue_1_clear")
                .else g, "beatloop_2_toggle"
            @add c.ledButton(0x20 + offset[2])
                .when(@cycle, g, "hotcue_2_activate")
                .else.when(@marker, g, "hotcue_2_clear")
                .else g, "beatloop_4_toggle"
            @add c.ledButton(0x30 + offset[1])
                .when(@cycle, g, "hotcue_3_activate")
                .else.when(@marker, g, "hotcue_3_clear")
                .else g, "beatloop_8_toggle"
            @add c.ledButton(0x30 + offset[2])
                .when(@cycle, g, "hotcue_4_activate")
                .else.when(@marker, g, "hotcue_4_clear")
                .else g, "beatloop_16_toggle"
            @add c.ledButton(0x40 + offset[1])
                .when(@cycle, g, "hotcue_5_activate")
                .else.when(@marker, g, "hotcue_5_clear")
                .else g, "loop_halve"
            @add c.ledButton(0x40 + offset[2])
                .when(@cycle, g, "hotcue_6_activate")
                .else.when(@marker, g, "hotcue_6_clear")
                .else g, "loop_double"

### Initialization

The **init** method is called by Mixxx when the script is loaded. Here
we can initialize the state of Mixxx. In our case, we select the first
deck, such that all transport buttons are directly functional.

        init: ->
            @decks.select 0

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
