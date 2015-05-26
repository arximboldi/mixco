mixco.value
===========

Module that provides a series of expressions that re-evaluate
automatically whenever one of the leaf nodes of the expression tree
changes.

    events  = require 'events'
    util    = require './util'
    factory = util.factory


Value
-----

The **Value** instances represent an active value that changes with
time.  The actual value can be accessed via the `value` property.
Whenever the value changes, a `value` event is notified, using the
standard [**node.js** *events*](http://nodejs.org/api/events.html)
system.  To register a listener callback that is called whenever the
value changes, use the `on` method from the `events.EventEmitter`
interface.

    class exports.Value extends events.EventEmitter

        constructor: ({initial}={}) ->
            super
            @setMaxListeners 0
            if initial?
                @value = initial

        @property 'value',
            get: -> @_value
            set: (newValue) ->
                @setValue newValue

        setValue: (newValue) ->
            if @_value != newValue
                @_value = newValue
                @emit 'value', newValue
            @_value

    exports.value = factory exports.Value


### Constants

Constants are lightweight objects that behave like a exports.Value,
but can not be modified -- at least, they will not trigger a
modification when modified.

    class exports.Const

        value: undefined

        constructor: (initial=undefined) ->
            @value = initial

It has to mock the events.EventEmitter interface.

        on: ->
        addListener: ->
        removeListener: ->
        listeners: -> []

    exports.const = factory exports.Const


High-order values
-----------------

Higher order values take a function as a parameter and a set of
other values.

A **Reduce** value combines N values applying a reduction (i.e. fold)
operation on them.  It updates whenever one of them changes.

    class exports.Reduce extends exports.Value

        constructor: (@reducer, @reduced...) ->
            super()
            for v in @reduced
                v.on 'value', => @update()
            @update()

        update: ->
            @value = @reduced
                .reduce((a, b) => exports.const @reducer a.value, b.value)
                .value

    exports.reduce = factory exports.Reduce
    exports.and    = -> exports.reduce ((a, b) -> a and b), arguments...
    exports.or     = -> exports.reduce ((a, b) -> a or b), arguments...


A **Transform** value holds a transformation of some other value by a
unary function.

    class exports.Transform extends exports.Value

        constructor: (@transformer, @transformed) ->
            super()
            @transformed.on 'value', => @update()
            @update()

        update: ->
            @value = @transformer @transformed.value

    exports.transform = factory exports.Transform
    exports.not       = -> exports.transform ((a) -> not a), arguments...

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
