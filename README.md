mixco
=====

**Mixco** is a framework for creating hardware controller scripts for
the amazing [Mixxx][mixxx] DJ software using [Literate
CoffeeScript][lcs]. Find more information [in the *Mixco*
webpage][mixco]. And remember, this is [Free Software][gnu].

  [gnu]: http://www.gnu.org/philosophy/free-sw.html
  [mixxx]: http://www.mixxx.org
  [lcs]: http://coffeescript.org/#literate
  [mixco]: http://sinusoid.es/mixco

[![build status](https://secure.travis-ci.org/arximboldi/mixco.svg)](https://travis-ci.org/arximboldi/mixco)

Features
--------

  * Your script file is a single [Literate CoffeeScript][lcs] file.
  * The file can be executed to generate the XML mapping and converted
    to JS to be used as the controller script.
  * The generated XML file bypasses the script whenever possible for
    lower latency, but this is transparent to the script writer.
  * The API is very [fluent][fluent] and
    [declarative][declarative].
  * Because of [Literate CoffeeScript][lcs], the mappings are well
    documented, and the code itself is interleaved with the
    documentation, encouraging DJs to modify them and remove the
    artist/coder dicotomy. [See an example of it][script.korg_nanokontrol2]
  * The [Node.js][nodejs] libraries can be used in the scripts.
  * Scripts can be written in JavaScript or CoffeeScript too.
  * Tests are automatically generated for every script, so you can
    find errors in your script before loading it in Mixxx.

  [declarative]: http://en.wikipedia.org/wiki/Declarative_programming
  [fluent]: http://en.wikipedia.org/wiki/Fluent_interface
  [lcs]: http://coffeescript.org/#literate
  [script.korg_nanokontrol2]: script/korg_nanokontrol2.html
  [nodejs]: http://nodejs.org/


Supported hardware
------------------

  - [Korg Nanokontrol 2][script.korg_nanokontrol2]
  - [M-Audio Xponent][script.maudio_xponent]
  - [Novation Twitch][script.novation_twitch]

  [script.korg_nanokontrol2]: script/korg_nanokontrol2.html
  [script.maudio_xponent]: script/maudio_xponent.html
  [script.novation_twitch]: script/novation_twitch.html


Download
--------

**Mixco** is still on development, but you can try it out grabbing the
source code from [Github][git]. Note that the project is still
***very experimental*** and thus the provided API will change every
single minute.

  [git]: https://github.com/arximboldi/mixco/

Depedencies
-----------

Required dependencies to compile the Mixxx scripts:

  - [CoffeeScript](http://coffeescript.org/) >= 1.5
  - [Node.js](http://nodejs.org/) >= 0.8
  - [Underscore](http://underscorejs.org/) >= 1.5
  - [Browserify](http://browserify.org/) >= 2.0
  - [GNU make](http://www.gnu.org/software/make/)

Optional dependencies:

  - [Docco](http://jashkenas.github.io/docco/) >= 0.6
  - [jasmine-node](https://github.com/mhevery/jasmine-node) >= 1.3.1

To install the dependencies, once you install
[Node.js](http://nodejs.org/), you may execute this in the project
folder:

> npm install

Installation
------------

To install the *Mixco*, first, [grab the sources][git].  From the
project folder, execute:

> make

The Mixxx compatible script files should be then `out/` folder, ready
to be copied to the [Mixxx MIDI controller folder][mixxxmidi]

To **compile** your own scripts, copy your `myscript.litcoffee` to the
`script/` folder, then execute from the project folder:

> make "SCRIPTS=out/myscript.midi.xml out/myscript.js"

Your script will be compiled and the `out` folder will contain your
script files ready to be used with Mixxx.  You can also compile
beautiful documentation like this doing:

> make doc DOCS=doc/script/myscript.html

Also, there is an automatic testing facility that will try to find
errors in all the scripts in the `script/` folder.  Run such tests
with:

> make test

  [git]: https://gitorious.org/mixco
  [mixxxmidi]: http://www.mixxx.org/wiki/doku.php/midi_controller_mapping_file_format


Documentation
-------------

### Scripts

  * [script.korg_nanokontrol2][script.korg_nanokontrol2]
  * [script.maudio_xponent][script.maudio_xponent]
  * [script.novation_twitch][script.novation_twitch]

### API

  * [mixco.behaviour][mixco.behaviour]
  * [mixco.control][mixco.control]
  * [mixco.multi][mixco.multi]
  * [mixco.script][mixco.script]
  * [mixco.transform][mixco.transform]
  * [mixco.util][mixco.util]
  * [mixco.value][mixco.value]

### Tests

  * [spec.mixco.behaviour][spec.mixco.behaviour]
  * [spec.mixco.control][spec.mixco.control]
  * [spec.mixco.multi][spec.mixco.multi]
  * [spec.mixco.script][spec.mixco.script]
  * [spec.mixco.value][spec.mixco.value]
  * [spec.mock][spec.mock]
  * [spec.scripts][spec.scripts]

  [script.korg_nanokontrol2]: script/korg_nanokontrol2.html
  [script.maudio_xponent]: script/maudio_xponent.html
  [script.novation_twitch]: script/novation_twitch.html

  [mixco.behaviour]: mixco/behaviour.html
  [mixco.control]: mixco/control.html
  [mixco.multi]: mixco/multi.html
  [mixco.script]: mixco/script.html
  [mixco.transform]: mixco/transform.html
  [mixco.util]: mixco/util.html
  [mixco.value]: mixco/value.html

  [spec.mixco.behaviour]: spec/mixco/behaviour.spec.html
  [spec.mixco.control]: spec/mixco/control.spec.html
  [spec.mixco.multi]: spec/mixco/multi.spec.html
  [spec.mixco.script]: spec/mixco/script.spec.html
  [spec.mixco.value]: spec/mixco/value.spec.html
  [spec.mock]: spec/mock.html
  [spec.scripts]: spec/scripts.spec.html


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
