mixco.expression
================

Module that provides a series of expressions that re-evaluate
automatically whenever one of the leaf nodes of the expression tree
changes.

Dependencies
------------

    events = require 'events'
    util   = require './util'

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

        constructor: (initial=undefined) ->
            @setMaxListeners 0
            if initial?
                @value = initial

        @property 'value',
            get: -> @_value
            set: (newValue) ->
                if @_value != newValue
                    @_value = newValue
                    @emit 'value', newValue
                @_value


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

    exports.const = -> new exports.Const arguments...


High-order values
-----------------

Higher order values take a function as a parameter and a set of
other values.

A **Reduce** value combines N values applying a reduction (i.e. fold)
operation on them.  It updates whenever one of them changes.

    class exports.Reduce extends exports.Value

        constructor: (@reducer, @reduced...) ->
            for v in @reduced
                v.on 'value', => do @update
            do @update

        update: ->
            @value = @reduced
                .reduce((a, b) => exports.const @reducer a.value, b.value)
                .value

    exports.reduce = -> new exports.Reduce arguments...
    exports.and = -> exports.reduce ((a, b) -> a and b), arguments...
    exports.or = -> exports.reduce ((a, b) -> a or b), arguments...


A **Transform** value holds a transformation of some other value by a
unary function.

    class exports.Transform extends exports.Value

        constructor: (@transformer, @transformed) ->
            @transformed.on 'value', => do @update
            do @update

        update: ->
            @value = @transformer @transformed.value

    exports.transform = -> new exports.Transform arguments...
    exports.not = -> exports.transform ((a) -> not a), arguments...
