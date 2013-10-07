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

var _      = require('underscore')
var script = require('../mixco/script')
var c      = require('../mixco/control')
var b      = require('../mixco/behaviour')
var v      = require('../mixco/value')

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

    constructor: function () {

	// #### Master section
	//
	// Many of the master controls of the that the *pre-hear
	// volume*, *pre-hear mix*, *booth volume* and *master volume*
	// knobs are handled directly by the integrated soundcard of
	// the controller.  We map the rest here.
	//
	// * *Crossfader* slider.

	c.slider(0x08, 0x07).does("[Master]", "crossfader")

	// #### Mic/aux and effects
	//
	// Sadly, the buttons *Aux*, *Deck A*, *Deck B* and *Pre-hear*
	// of the effects and microphone sections are controlled by
	// the hardware in a bit of a useless way, so they do nothing
	// -- other than light up when they are pressed.

	var ccIdFxBanks = function (index) {
	    banks  = 5
	    params = 4
	    ids    = []
	    for (var j = 0; j < banks; ++j)
		ids.push.apply(ids, c.ccIds(index + params * j, 0xB))
	    return ids
	}

	// * Microphone *volume* control and *on/off* button.

	c.knob(ccIdFxBanks(0x3)).does(b.soft("[Microphone]", "volume"))
	c.ledButton(c.noteIds(0x23, 0xB)).does("[Microphone]", "talkover")

	// * The knobs in the *Master FX* section are mapped to
	//   *depth*, *delay* and *period* -- in this order.

	c.knob(ccIdFxBanks(0x0)).does("[Flanger]", "lfoDepth")
	c.encoder(ccIdFxBanks(0x1)).does("[Flanger]", "lfoDelay")
	    .option(scaledDiff(3))
	c.encoder(3, ccIdFxBanks(0x2)).does("[Flanger]", "lfoPeriod")
	    .option(scaledDiff(3))

        // * The *on/off* button of the FX section does a bilateral
        //   *punch-in* -- i.e. temporarily moves the crossfader to
        //   the center while held, if it was far from the center.

        c.ledButton(c.noteIds(0x22, 0xB)).does(b.punchIn(-0.5, 0.5))

	// #### Browse
	//
	// * The *back* and *fwd* can be used to scroll the sidebar.

	c.button(c.noteIds(0x54, 0x7)).does(
	    "[Playlist]", "SelectPrevPlaylist")
	c.button(c.noteIds(0x56, 0x7)).does(
	    "[Playlist]", "SelectNextPlaylist")

	// * The *scroll* encoder scrolles the current view.  When
	//   pressed it moves faster.

	scrollFaster = b.modifier()

        c.button(c.noteIds(0x55, 0x7)).does(scrollFaster)
	c.knob(0x55, 0x7)
	    .when (scrollFaster,
                   b.map("[Playlist]", "SelectTrackKnob")
		       .option(scaledSelectKnob(8)))
	    .else_(b.map("[Playlist]", "SelectTrackKnob")
		       .options.selectknob)

	// * The *area* button expand or collapses the selected
	//   element cathegory in the sidebar.

	c.ledButton(c.noteIds(0x50, 0x7)).does(
	    "[Playlist]", "ToggleSelectedSidebarItem")

        // * The *view* button in the *browser* section lets you tap
        //   the tempo for the track that is currently on pre-hear.

        this.viewButton = c.ledButton(c.noteIds(0x51, 0x7))

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

    addDeck: function (i) {
	var g           = "[Channel" + (i+1) + "]"
	var ccId        = function (cc)   { return c.ccIds(cc, 0x07+i) }
	var ccIdShift   = function (cc)   { return c.ccIds(cc, 0x09+i) }
	var ccIdAll     = function (cc)   { return _.union(ccId(cc),
							   ccIdShift(cc)) }
	var noteId      = function (note) { return c.noteIds(note, 0x07+i) }
	var noteIdShift = function (note) { return c.noteIds(note, 0x09+i) }
	var noteIdAll   = function (cc)   { return _.union(noteId(cc),
							   noteIdShift(cc)) }

	// #### Mixer section
	//
	// * Pre-hear deck selection.

	c.ledButton(noteIdAll(0x0A)).does(this.decks.add(g, "pfl"))

        this.viewButton.when(this.decks.activator(i),
                             g, "bpm_tap", g, "beat_active")

	// * *Volume* fader and *low*, *mid*, *high* and *trim* knobs.

	c.slider(ccIdAll(0x07)).does(g, "volume")
	c.knob(ccIdAll(0x46)).does(g, "filterLow")
	c.knob(ccIdAll(0x47)).does(g, "filterMid")
	c.knob(ccIdAll(0x48)).does(g, "filterHigh")
	c.knob(ccIdAll(0x09)).does(g, "pregain")

        // * *Volume* meters for each channel.

        c.meter(noteIdAll(0x5f)).does(b.mapOut(g, "VuMeter").meter())

	// * The **fader FX** we use as a knob-controlled *beat
	//   looproll effect*. Effect can be turned on by pressing the
	//   knob or the on/off button.

	var faderfx = b.beatEffect(g, 'roll')
	c.encoder(ccIdAll(0x06)).does(faderfx.selector())
	c.control(noteIdAll(0x06)).does(faderfx.momentary())
	c.ledButton(noteIdAll(0x0D)).does(faderfx.options.switch_)

	// #### Effects
	//
	// * In the *Master FX* section, the *FX Select* left and
	//   right enable the flanger in the direction of the arrow.

	c.ledButton(c.noteIds(0x20+i, 0xB)).does(g, "flanger")

	// #### Browse
	//
	// * The *load A* or *load B* buttons load the selected track
	//   to the given deck.

	c.ledButton(c.noteIds(0x52+i, 0x7)).does(g, "LoadSelectedTrack")

	// #### Deck transport
	//
	// * The *play* and *cue* buttons work as expected. On
	//   *shift*, the cue button does a reverse effect.

	var redLed   = 0x00
	var amberLed = 0x40
	var greenLed = 0x70
	var ledPad   = function (ids, color) {
	    return c.ledButton(ids).states({
		on:  color + 0xf,
		off: color + 0x1
	    })
	}

	ledPad(noteIdAll(0x17), greenLed).does(g, "play")
	ledPad(noteId(0x16), redLed).does(g, "cue_default")
	ledPad(noteIdShift(0x16), amberLed).does(g, "reverse")

	// * The *keylock* button toggles the pitch-independent time
	//   stretching.  On *shift*, it toggles *slip mode*, in which
	//   loops and scratching continue playback on the background
	//   thus returning the playhead to where the track would have
	//   been.

	slipMode = b.switch_()
	c.ledButton(noteId(0x12)).does(g, "keylock")
	c.ledButton(noteIdShift(0x12)).does(slipMode)

	// * The *sync* button aligns phase and tempo of this track to
	//   the one of the other deck.  On *shift*, it aligns tempo
	//   only.

	c.ledButton(noteId(0x13)).does(g, "beatsync")
	c.ledButton(noteIdShift(0x13)).does(g, "beatsync_tempo")

	// #### Beat grid
	//
	// * The *adjust* button *aligns the beatgrid* to the current
	//   play position.

	c.ledButton(noteIdAll(0x11)).does(g, "beats_translate_curpos")

	// * The *set* button toggles loop and hot-cue *quantization*
	//   on or off.

	c.ledButton(noteIdAll(0x10)).does(g, "quantize")

	// #### Pitch and transport bar
	//
	// * The *pitch* encoder moves the pitch slider up and
	//   down. When it is pressed, it moves it pitch faster.

	var coarseRateFactor = 1/10
	var coarseRateOn     = b.modifier()

	c.button(noteIdAll(0x03)).does(coarseRateOn)
	c.knob(ccIdAll(0x03))
	    .when (coarseRateOn,
		   b.map(g, "rate").option(scaledDiff(2)))
	    .else_(b.map(g, "rate").option(scaledDiff(1/12)))

	// * In *drop* mode, the touch strip scrolls through the song.

	c.slider(ccId(0x34)).does(g, "playposition")

	// * In *swipe* mode, the touch strip nudges the pitch up and
	//   down.  When *shift* is held it simulates scratching.

	c.input(ccId(0x35)).does(g, "jog")
            .option(scaledSelectKnob(1/3))
	c.slider(ccIdShift(0x35)).does(b.scratchTick(i+1))
	    .options.selectknob,
	c.button(noteIdShift(0x47))
	    .does(b.scratchEnable(i+1, 128))
	    .when(slipMode, b.map(g, "slip_enabled").options.switch_)

	// #### Performance modes
	//
	// ##### Hot cues
	//
	// * In *hot-cues* mode, the performance buttons control the
	//   hot cues.  One may *clear* hot-cues with *shift*.

	for (var j = 0; j < 8; ++j) {
	    ledPad(noteId(0x60+j), amberLed).does(
		g, "hotcue_" + (j+1) + "_activate",
		g, "hotcue_" + (j+1) + "_enabled")
	    ledPad(noteIdShift(0x60+j), amberLed).does(
		g, "hotcue_" + (j+1) + "_clear",
		g, "hotcue_" + (j+1) + "_enabled")
        }

	// ##### Slicer
	//
	// There is no functionality like a *slicer* in Mixxx, but we
	// reuse these pads for various purposes in this mode.
	//
	// * The buttons *1 to 4* trigger the first four samplers.
	//   The sample plays as long as the button is held.

	for (var j = 0; j < 4; ++j)
	    ledPad(noteIdAll(0x68+j), redLed).does(
		"[Sampler" + (j+1) + "]", "cue_preview")

	// * The buttons *5 and 6* trigger a *spinback* and *brake*
	//   effect respectively.

	ledPad(noteIdAll(0x6C), greenLed).does(b.spinback(i+1))
	ledPad(noteIdAll(0x6D), greenLed).does(b.brake(i+1))

	// * The buttons *7 and 7* perform a stutter effect at
	//   different speeds.

	ledPad(noteIdAll(0x6E), amberLed).does(b.stutter(g, 1/8))
	ledPad(noteIdAll(0x6F), amberLed).does(b.stutter(g, 1/4))

	// ##### Auto loop
	//
	// * In *auto-loop* mode, the pads select *loops* of sizes
	//   1/16, 1/8, 1/4, 1/2, 1, 2, 4 or 8 beats.  On *shift*, it
	//   creates loops of sizes 1, 2, 4, 8, 16, 32 or 64 beats.

	loopSize = [ "0.0625", "0.125", "0.25", "0.5",
		     "1",      "2",     "4",    "8",
		     "16",     "32",    "64" ]
	for (var j = 0; j < 8; ++j)
	    ledPad(noteId(0x70+j), greenLed).does(
		g, "beatloop_" + loopSize[j] + "_toggle",
		g, "beatloop_" + loopSize[j] + "_enabled")
	for (var j = 0; j < 7; ++j)
	    ledPad(noteIdShift(0x70+j), greenLed).does(
		g, "beatloop_" + loopSize[4+j] + "_toggle",
		g, "beatloop_" + loopSize[4+j] + "_enabled")

	// ##### Loop roll
	//
	// * In *loop-roll* mode, it same as the beatloop mode but the
	//   effect is momentary and returns the playhead to where it
	//   would have been without looping.

	for (var j = 0; j < 8; ++j)
	    ledPad(noteId(0x78+j), greenLed).does(
		g, "beatlooproll_" + loopSize[j] + "_activate",
		g, "beatloop_" + loopSize[j] + "_enabled")
	for (var j = 0; j < 7; ++j)
	    ledPad(noteIdShift(0x78+j), greenLed).does(
		g, "beatlooproll_" + loopSize[4+j] + "_activate",
		g, "beatloop_" + loopSize[4+j] + "_enabled")

    },

    // ### Initialization
    //
    // The `preinit` function is called before the MIDI controls are
    // initialized.  We are going to set the device in *basic mode*,
    // as mentioned in the manual. This means that mode management is
    // done by the device -- this will simplify the script and let
    // have direct lower latency mappings more often.

    preinit: function () {
	this.mixxx.midi.sendShortMsg(0xb7, 0x00, 0x6f)
	this.mixxx.midi.sendShortMsg(0xb7, 0x00, 0x00)
    },

    init: function () {
	this.decks.activate(0)
    },

    // ### Shutdown
    //
    // The documentation suggests to reset the device when the program
    // shuts down. This means that all the lights are turned off and
    // the device is in basic mode, ready to be used by some other
    // program.

    postshutdown: function () {
	this.mixxx.midi.sendShortMsg(0xb7, 0x00, 0x00)
    }

});

// Utilities
// ---------
//
// The *scaledDiff* function returns a behaviour option that is useful
// to define encoders with a specific sensitivity, which is useful to
// correct the issues of the stepped encoders.

function scaledDiff (factor) {
    return function (v, v0) {
	return (v0 + factor * (v > 64 ? v - 128 : v)).clamp(0, 128)
    }
}

function scaledSelectKnob (factor) {
    return function (v, b) {
	return factor * (v > 64 ? v - 128 : v)
    }
}

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
