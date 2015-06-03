mixco
=====

[**Mixco**][mixco] is a framework for creating hardware
[controller scripts][scripts] for the amazing [Mixxx][mixxx] DJ
software.  It makes the process **easier** and **faster**, and
resulting scripts are often more **robust**, ready to be rock big
parties.

And remember, this is [Free Software][gnu].

  [scripts]: http://mixxx.org/wiki/doku.php/midi_scripting
  [gnu]: http://www.gnu.org/philosophy/free-sw.html
  [mixxx]: http://www.mixxx.org
  [lcs]: http://coffeescript.org/#literate
  [mixco]: http://sinusoid.es/mixco

<a href="http://badge.fury.io/js/mixco"><img src="https://badge.fury.io/js/mixco.svg"/></a>
<a href="https://travis-ci.org/arximboldi/mixco"><img src="https://travis-ci.org/arximboldi/mixco.svg"/></a>
<a href="https://coveralls.io/r/arximboldi/mixco"><img src="https://coveralls.io/repos/arximboldi/mixco/badge.svg"/></a>

Installation
------------

Mixco is based on the [NodeJS][nodejs] JavaScript development
environment so, first, you need to [install it][nodedown].  Then, just
run in the command line:

> ```
> npm install -g mixco
> ```

You can also [browse the code on Github][github].

  [github]: http://github.com/arximboldi/mixco
  [nodejs]: http://nodejs.org/
  [nodedown]: http://nodejs.org/download

Examples
--------

Mixco comes with a series of factory controller scripts.  They are
well documented and their code serves as good tutorial on how to use
the framework.

  - [Novation Twitch][script.novation_twitch]
  - [Korg Nanokontrol 2][script.korg_nanokontrol2]
  - [M-Audio Xponent][script.maudio_xponent]

To **install** these, run on the command line:

> ```
> mixco --factory
> ```

  [script.korg_nanokontrol2]: http://sinusoid.es/mixco/script/korg_nanokontrol2.mixco.html
  [script.maudio_xponent]: http://sinusoid.es/mixco/script/maudio_xponent.mixco.html
  [script.novation_twitch]: http://sinusoid.es/mixco/script/novation_twitch.mixco.html

Features
--------

#### Write more high level code

The programming interface is very [fluent][fluent] and
[declarative][declarative], allowing you to write more high level
code. For example, imagine this feature: *when the sync button aligns
the phase or not depending on whether the shift button is pressed*.
While normally this would involve quite a few lines of code detecting
whether shift is pressed, controlling the lights of the buttons, and
so on, With Mixco this can be written simply as:

```js
var mixco = require('mixco')
var c = mixco.controls
var b = mixco.behaviours

// ... in your script constructor ...
    var shift = b.modifier()
    ledButton(c.noteIds 0x01, 0).does(shift)

    var g = "[Channel1]"
    b.ledButton(c.noteIds 0x02, 0)
        .when(shift, g, "beatsync_tempo")
        .else_(g, "beatsync")
```

#### No editing XML files

Normally, Mixxx requires that you describe every MIDI message that
your controller can receive in [a verbose XML file][xmlspec].  Mixco
generates this file for you from your JavaScript file, so you can
focus on adding cool features to your mapping.

  [xmlspec]: http://mixxx.org/wiki/doku.php/midi_controller_mapping_file_format

#### No duplicate per-deck code

Most DJ oriented MIDI controllers are mostly symmetric, with controls
duplicated per deck.  Since we don't need a XML mapping, you can avoid
duplicating the code: just write a function that defines the
functionality for one deck, and call it several times.  For an
example, look at the `addDeck()` function of
[this tutorial script][script.novation_twitch].

#### Use external libraries and modularize your code

If your script is big and complicated, you can split it into multiple
files to make it easier to maintain, by using the `require()`
function.  Even cooler, most libraries installed with `npm`, the
[NodeJS package manager][npm], work out of the box.  Mixco will
compile your script into a single bundle that Mixxx can use and is
easy to redistribute. For example:

```js
// file: my-utils.js
exports.doSomething = function() { ... }
```

```js
// file: my-script.mixco.js
// importing the framework
var mixco = require('mixco')
// using a external library: https://www.npmjs.com/package/underscore
var _ = require('underscore')
// Using custom module
var utils = require('./my-utils')
utils.doSomething()
```

#### Automatically test your code

In JavaScript, it is easy to make tiny mistake that break your code.
Mixco can run some basic tests on your scripts, so some simple
problems can be found before even loading it into Mixxx.

Also, Mixco be run in **watch mode**: whenever you change your script,
it will re-run the tests and, when successful, recompile the script so
it's reloaded inside Mixxx.

#### Use languages different from JavaScript

If you are like me, you don't like JavaScript so much.  Mixco supports
[CoffeeScript][coffee], a nice language with syntax inspired by Python
and Ruby that polishes some of the rough corners of JavaScript.  Mixco
can automatically compile CoffeeScript script to JavaScript and, in
the future, other languages too.

#### Generate beautiful documentation

Documenting a script is hard but important: otherwise your users are
clue-less about what each button of the controler does.  Mixco
encourages a style of programming known as
[literate programming][litprog], which mixes code with documentation
about what it does.  If you code in that style, it can generate
beautiful [web pages like this][script.novation_twitch], that teach
your users not only what the script does, but also what code they
should is creating that functionality, encouraging people to improve
the scripts and create their own mods.

  [npm]: https://www.npmjs.com/
  [litprog]: https://en.wikipedia.org/wiki/Literate_programming
  [declarative]: http://en.wikipedia.org/wiki/Declarative_programming
  [fluent]: http://en.wikipedia.org/wiki/Fluent_interface
  [lcs]: http://coffeescript.org/#literate
  [coffee]: http://coffeescript.org/
  [script.korg_nanokontrol2]: http://sinusoid.es/mixco/script/korg_nanokontrol2.mixco.html
  [script.maudio_xponent]: http://sinusoid.es/mixco/script/maudio_xponent.mixco.html
  [script.novation_twitch]: http://sinusoid.es/mixco/script/novation_twitch.mixco.html

Usage
-----

Mixco comes with a program called, ehem, **mixco**, that compiles all
the scripts in the current directory to a form that can be used inside
Mixxx.  Try this by creating a file `my_script.mixco.js` and run this
in the same folder:

> ```
> mixco
> ```

> ```
> info:    inputs: .
> info:    output directory: mixco-output
> info:    generated: <...>/mixco-output/my_script.mixco.output.js
> info:    generated: <...>/mixco-output/my_script.mixco.output.midi.xml
> ```

Mixco can `watch` the filesystem so you don't need to re-run the
command whenever you change the script.  It can also automatically run
tests on it and copy the script to some location, so Mixxx can see it.
For example, if you are on Linux, you might want to run the command
like this:

> ```
> mixco --watch --test -o /usr/share/mixxx/controllers
> ```

The **mixco** command can do much more:

> ```
> mixco --help
>
> Usage:
>        mixco [options] [<input>...]
>
> Mixco is a framework for making DJ controller scripts for Mixxx.
>
> This program can compile all the <input> Mixco scripts into .js and .xml files
> that can be used inside Mixxx. Mixco scripts have one of the following
> extensions: *.mixco.js, *.mixco.coffee, *.mixco.litcoffee. When no <input> is
> passed, it will compile all scripts in the current directory. When an <input> is
> a directory, all scripts found in it will be compiled.
>
> Options:
>   -o, --output=PATH           Directory where to put the generated files
>                                 Default: mixco-output
>   -r, --recursive             Recursively look for scripts in input directories
>   -w, --watch                 Watch scripts for changes and recompile them
>   -T, --self-test             Test the framework before compilation
>   -t, --test                  Test the input scripts before compilation
>       --factory               Compile the scripts that come with Mixco
>   -h, --help                  Display this help message and exit
>   -V, --verbose               Print more output
>   -v, --version               Output version information and exit
>
> More info and bug reports at: <http://sinusoid.es/mixco>
> ```

Documentation
-------------

### Scripts

  * [script.korg_nanokontrol2][script.korg_nanokontrol2]
  * [script.maudio_xponent][script.maudio_xponent]
  * [script.novation_twitch][script.novation_twitch]

### API

  * [mixco.behaviour][mixco.behaviour]
  * [mixco.cli][mixco.cli]
  * [mixco.control][mixco.control]
  * [mixco.console][mixco.control]
  * [mixco.script][mixco.script]
  * [mixco.transform][mixco.transform]
  * [mixco.util][mixco.util]
  * [mixco.value][mixco.value]

### Tests

  * [spec.mixco.behaviour][spec.mixco.behaviour]
  * [spec.mixco.control][spec.mixco.control]
  * [spec.mixco.script][spec.mixco.script]
  * [spec.mixco.value][spec.mixco.value]
  * [spec.mock][spec.mock]
  * [spec.scripts][spec.scripts]

  [script.korg_nanokontrol2]: http://sinusoid.es/mixco/script/korg_nanokontrol2.mixco.html
  [script.maudio_xponent]: http://sinusoid.es/mixco/script/maudio_xponent.mixco.html
  [script.novation_twitch]: http://sinusoid.es/mixco/script/novation_twitch.mixco.html

  [mixco.behaviour]: http://sinusoid.es/mixco/src/behaviour.html
  [mixco.cli]: http://sinusoid.es/mixco/src/cli.html
  [mixco.control]: http://sinusoid.es/mixco/src/control.html
  [mixco.console]: http://sinusoid.es/mixco/src/console.html
  [mixco.script]: http://sinusoid.es/mixco/src/script.html
  [mixco.transform]: http://sinusoid.es/mixco/src/transform.html
  [mixco.util]: http://sinusoid.es/mixco/src/util.html
  [mixco.value]: http://sinusoid.es/mixco/src/value.html

  [spec.mixco.behaviour]: http://sinusoid.es/spec/mixco/behaviour.spec.html
  [spec.mixco.control]: http://sinusoid.es/spec/mixco/control.spec.html
  [spec.mixco.script]: http://sinusoid.es/spec/mixco/script.spec.html
  [spec.mixco.value]: http://sinusoid.es/spec/mixco/value.spec.html
  [spec.mock]: http://sinusoid.es/spec/mock.html
  [spec.scripts]: http://sinusoid.es/spec/scripts.spec.html

Contributing
------------

Please, log **bugs, questions or feature requests** in the
[Github issue tracker][issues].

We are also **happy to accept contributions**, either improvements to the
frameworks, new factory scripts or documentation
enhacements. [Fork us on GitHub][github] or by running:

> ```
> git clone https://github.com/arximboldi/mixco.git
> ```

You can also **contact me** by email at: `raskolnikov@gnu.org`.

  [github]: http://github.com/arximboldi/mixco
  [issues]: http://github.com/arximboldi/mixco/issues

License
-------

>  Copyright (C) 2013, 2015 Juan Pedro Bolívar Puente
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
