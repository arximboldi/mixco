// script.twitch
// =============
//
// Mixx script file for the **Novation Twitch** controller.  The
// script is based on the [**Mixco** framework](../index.html)
// framework.
//
// This script serves as **tutorial** for creating scripts using the
// *Mixco* framework, but programming directly in JavaScript.  Still,
// we recommend you to try CoffeeScript, since it is a bit of a nicer
// language.
//
// If you want to modify this script, you may want to read the
// [Novation Twitch Programmer
// Guide](www.novationmusic.com/download/799/‎)
//
// ### Note for Linux Users
//
// The Linux Kernel version 3.10 is required to get Novation Twitch
// detected as soundcard or MIDI device.
//
//   ![Novation Twitch Layout](../pic/novation_twitch.png)
//
// Dependencies
// ------------
//
// First, we have to import the modules from the framework.  We use
// that the *NodeJS* `require` function.  Note that all other NodeJS
// modules are usable too when writing your script with the *Mixco*
// framework.

var script = require('../mixco/script')

var c = require('../mixco/control')
var b = require('../mixco/behaviour')
var v = require('../mixco/value')

// The script
// ----------
//
// When writing a controller script we use the `script.register`
// function to generate and install a script instance in the current
// module.  The first parameter is the current module as defined by
// *NodeJS*, the second parameter is the JavaScript object with all
// the functions and information about our script.

script.register(module, {

    // ### Metadata
    //
    // The `name` attribute is very important, and it has to be
    // exactly the name of this file *without extension*.  Then the
    // `info` object contains the meta-data that is displayed to the
    // user in the MIDI mapping chooser of Mixxx.

    name: "novation_twitch",

    info: {
	name: "[mixco] Novation Twitch",
	author: "Juan Pedro Bolivar Puente"
    },

    // ### Constructor
    //
    // The constructor contains the definition of the MIDI mapping.
    // Here we create all the different control objects and add them
    // to the script instance.

    constructor: function() {

	// #### Master section
	//
	// Many of the master controls of the that the *pre-hear
	// volume*, *pre-hear mix*, *booth volume* and *master volume*
	// knobs are handled directly by the integrated soundcard of
	// the controller.  We map the rest here.
	//
	// * *Crossfader* slider.

	this.add(c.slider(0x08, 0x07).does(b.soft("[Master]", "crossfader")))

	// #### Microphone
	//
	// Note that the pre-hear button is controlled directly by the
	// integrated soundcard.
	//
	// * Microphone *volume* control and *on/off* button.

	this.add(
	    c.knob(0x03, 0xB).does(b.soft("[Microphone]", "volume")),
	    c.ledButton(c.noteIds(0x23, 0xB)).does("[Microphone]", "talkover")
	)

	// ### Per deck controls
	//
	// We use a `behaviou.chooser` for the PFL selection.  This
	// will make sure that only one prehear channel is selected at
	// a time for greater convenience. Then, we define a `addDeck`
	// function that will add the actual controls for each of the
	// decks.

	this.decks = b.chooser()
	this.addDeck(0)
	this.addDeck(1)
    },

    addDeck: function(i) {
	var g           = "[Channel" + (i+1) + "]"
	var ccId        = function(cc)   { return c.ccIds(cc, 0x07+i) }
	var noteId      = function(note) { return c.noteIds(note, 0x07+i) }
	var noteIdShift = function(note) { return c.noteIds(note, 0x09+i) }

	// #### Mixer section
	//
	// * Pre-hear deck selection.

	this.add(c.ledButton(noteId(0x0A)).does(this.decks.add(g, "pfl")))

	// * *Volume* fader and *low*, *mid*, *high* and *trim* knobs.

	this.add(
	    c.slider(ccId(0x07)).does(g, "volume"),
	    c.knob(ccId(0x46)).does(g, "filterLow"),
	    c.knob(ccId(0x47)).does(g, "filterMid"),
	    c.knob(ccId(0x48)).does(g, "filterHigh"),
	    c.knob(ccId(0x09)).does(b.soft(g, "pregain"))
	)

	// * The **fader FX** we use as a knob-controlled *beat
	//   looproll effect*. Effect can be turned on by pressing the
	//   knob or the on/off button.

	faderfx = b.beatEffect(g, 'roll')
	this.add(
	    c.knob(ccId(0x06)).does(faderfx.selector().options.diff),
	    c.control(noteId(0x06)).does(faderfx.momentary()),
	    c.ledButton(noteId(0x0D)).does(faderfx)
	)

	// #### Deck play
	//
	// * The transport section controls *play, cue, keylock and
	//   sync*.  When *shift* is *on*, the sync will synchronize
	//   only tempo, otherwise it also matches the phase. Also,
	//   the play button will do a *reverse* toggle when shift is
	//   held.

	this.add(
	    c.ledButton(noteId(0x17)).does(g, "play"),
	    c.ledButton(noteIdShift(0x17)).does(g, "reverse"),
	    c.ledButton(noteId(0x16)).does(g, "cue_default"),
	    c.ledButton(noteId(0x12)).does(g, "keylock"),
	    c.ledButton(noteId(0x13)).does(g, "beatsync"),
	    c.ledButton(noteIdShift(0x13)).does(g, "beatsync_tempo")
	)

    },

    // ### Initialization
    //
    // The `preinit` function is called before the MIDI controls are
    // initialized.  We are going to set the device in *basic mode*,
    // as mentioned in the manual. This means that mode management is
    // done by the device -- this will simplify the script and let
    // have direct lower latency mappings more often.

    preinit: function() {
	this.mixxx.midi.sendShortMsg(0xb7, 0x00, 0x6f)
	this.mixxx.midi.sendShortMsg(0xb7, 0x00, 0x00)
    },

    // ### Shutdown
    //
    // The documentation suggests to reset the device when the program
    // shuts down. This means that all the lights are turned off and
    // the device is in basic mode, ready to be used by some other
    // program.

    shutdown: function() {
	this.mixxx.midi.sendShortMsg(0xb7, 0x00, 0x00)
    }

});

// >  Copyright (C) 2013 Juan Pedro Bolívar Puente
// >
// >  This program is free software: you can redistribute it and/or
// >  modify it under the terms of the GNU General Public License as
// >  published by the Free Software Foundation, either version 3 of the
// >  License, or (at your option) any later version.
// >
// >  This program is distributed in the hope that it will be useful,
// >  but WITHOUT ANY WARRANTY; without even the implied warranty of
// >  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// >  GNU General Public License for more details.
// >
// >  You should have received a copy of the GNU General Public License
// >  along with this program.  If not, see <http://www.gnu.org/licenses/>.
