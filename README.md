mixco
=====

**mixco** is a framework for creating hardware controller scripts for
the amazing [Mixxx][mixxx] DJ software using [Literate CoffeeScript][lcs].

Find more information [in the **mixco** webpage][mixco]. And remember,
**mixco** is [Free Software][gnu].

  [gnu]: http://www.gnu.org/philosophy/philosophy.html
  [mixxx]: http://www.gnu.org/philosophy/philosophy.html
  [lcs]: http://coffeescript.org/#literate
  [mixco]: http://sinusoid.es/mixco

Download
--------

**mixco** is still on development, but you can try it out grabbing the
source code from [Gitorious][git]. Note that the project is still
***very experimental*** and thus the API will change every single
minute.

  [git]: https://gitorious.org/mixco

Features
--------

  * Your script file is a single [Literate CoffeeScript][lcs] file
  * The file can be executed to generate the XML mapping and converted
    to JS to be used as the script.
  * Direct-mappings to controls whenever possible, but this is transparent
    to the script writer.
  * Most of the API is very declarative.
  * Because of [Literate CoffeeScript][lcs], the mappings are well
    documented, and they include the documentations contains the code
    itself, encouraging DJs to modify them and remove the artist/coder
    dicotomy. [See an example of it][script.nanokontrol2]

  [lcs]: http://coffeescript.org/#literate
  [script.nanokontrol2]: script/nanokontrol2.html


Supported hardware
------------------

  - [Korg Nanokontrol 2][script.nanokontrol2]

  [script.nanokontrol2]: script/nanokontrol2.html


Installation
------------

To install the *mixco* First, [grab the sources][git]. Then, from the
project folder, execute:

> make

The Mixxx compatible script files should be then `out/` folder, ready
to be copied to the [Mixxx MIDI controller folder][mixxxmidi]

To compile your own scripts, copy your `myscript.litcoffee` to the
`script/` folder, then execute from the project folder:

> make "SCRIPTS=out/myscript.midi.xml out/myscript.js"

Your script will be compiled and the `out` folder will contain your
script files ready to be used with Mixxx.  You can also compile
beautiful documentation like this doing:

> make doc DOCS=doc/script/myscript.html

  [git]: https://gitorious.org/mixco
  [mixxxmidi]: http://www.mixxx.org/wiki/doku.php/midi_controller_mapping_file_format


Documentation
-------------

### API

  * [mixco.script][mixco.script]
  * [mixco.control][mixco.control]
  * [mixco.behaviour][mixco.behaviour]
  * [mixco.transform][mixco.transform]
  * [mixco.util][mixco.util]

### Scripts

  * [script.nanokontrol2][script.nanokontrol2]

  [mixco.script]: mixco/script.html
  [mixco.control]: mixco/control.html
  [mixco.behaviour]: mixco/behaviour.html
  [mixco.transform]: mixco/transform.html
  [mixco.util]: mixco/util.html
  [script.nanokontrol2]: script/nanokontrol2.html


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
