mixco.util
==========

This module contains a series of utility functions.

Monkey patches
--------------

### Function

We provide a **property** class method to define *properties* --
i.e. attributes that are accessed via setters and getters.

    Function::property = (prop, desc) ->
        Object.defineProperty @prototype, prop, desc

### Number

    Number::clamp = (min, max) -> Math.min Math.max(this, min), max
    Number::sign = () -> if this < 0 then -1 else 1

### Array

    Array::equals = (other) ->
        @length is other.length and @every (elem, i) -> elem is other[i]


Utilities
---------

### Printer

This be used to print both into Mixxx console or the
standard output, for code paths that run both as Mixxx script or
standalone.

    exports.printer = (args...) ->
        try
            print args.toString()
        catch _
            console.error args.toString()

### Error management

This can be used to guard against any possible exception, printing an
error on the console when it happens.  This is specially useful in the
context of Mixxx.

    exports.catching = (f) -> ->
        try
            f.apply @, arguments
        catch err
            exports.printer "ERROR: #{err}"

Throws an error if *value* is false.  The *error* can be a custom string.

    exports.assert = (value, error=undefined) ->
        if not value
           throw new Error(if error? then error else "Assertion failed")

### String utilities

This tries to scape a string to be valid XML.

    exports.xmlEscape = (str) ->
        str
            .replace('&', '&amp;')
            .replace('"', '&quot;')
            .replace('>', '&gt;')
            .replace('<', '&lt;')

Generates a string that contains *depth* number of spaces.

    exports.indent = (depth) ->
        Array(depth*4).join(" ")

Generates a string with a C-style hexadecimal representation of a
number.

    exports.hexStr = (number) ->
        "0x#{number.toString 16}"

### Factories

Generates a function that constructs an object of type *Klass*,
forwarding all its parameters to the constructor.  I hate using the
`new` operator, so this will be used on most exported classes.

    exports.factory = (Klass) -> -> new Klass arguments...


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
