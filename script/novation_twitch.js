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
	this.add(
	    c.slider(0x08, 7).does("[Master]", "crossfader")
		.options.softTakeover)
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
