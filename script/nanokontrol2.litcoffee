script.nanokontrol2
===================

Mixxx script file for the **Korg NanoKontrol2** controller.

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


Dependencies
------------

The script is based on the *MixCo* framework.

    script    = require "../mixco/script"
    control   = require "../mixco/control"
    behaviour = require "../mixco/behaviour"


Implementation
--------------

    script.register module, class NanoKontrol2 extends script.Script

### Metadata

        info:
            name: '[MixCo] Korg Nanokontrol 2'
            author: 'Juan Pedro Bolivar Puente <raskolnikov@gnu.org>'
            description:
                """
                Controller mapping for Korg Nanokontrol 2 that is
                targetted at being used as main interface for Mixxx.
                """
            forums: ''
            wiki: ''

### Basic deck controls

Build the script object. We select exclusively the prehear, which will
serve as a notion of "selected deck" for certain actions.

        constructor: ->
            super
            @decks = behaviour.chooser "pfl"
            @addDeck 0
            @addDeck 1

The script adds the following controls per deck

        addDeck: (i) ->
            c = control
            b = behaviour
            g = "[Channel#{i+1}]"

The top 8 knobs are mapped to the two decks mixer filter section (low,
mid, high, gain).

            @add c.knob(0x10 + 4*i).does g, "filterLow"
            @add c.knob(0x11 + 4*i).does g, "filterMid"
            @add c.knob(0x12 + 4*i).does g, "filterHigh"
            @add c.knob(0x13 + 4*i).does b.soft g, "pregain"

Then the two first "control sections" are mapped like:

  * S: Selects the deck for prehear.
  * M: Cue button for the deck.
  * R: Play button for the deck.
  * The fader controls the volume of the deck.

            @add c.ledButton(0x40 + i).does g, "play"
            @add c.ledButton(0x30 + i).does g, "cue_default"
            @add c.ledButton(0x20 + i).does @decks.choose i
            @add c.slider(0x00 + i).does g, "volume"

The next two control sections control the pitch related stuff.

  * The fader controls the pitch of the deck.

            @add c.slider(0x02 + i).does b.soft g, "rate"
