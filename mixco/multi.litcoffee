mixco.multi
===========

Adds multiple inheritance support to CoffeeScript (and JavaScript).
It uses the C3 linearization algorithm as described in the [famous
Dylan paper](http://192.220.96.201/dylan/linearization-oopsla96.html).

    {head, tail, map, find, some, without, isEmpty, every, memoize} =
        require 'underscore'
    {assert} = require './util'


Multiple inheritance
--------------------

The **multi** function takes a list of classes and returns a *special*
class object that merges the class hierarchies, as linearized by the
C3 algorithm. Limitations of the approach are:

- *instanceof* does not always work as expected. For example:

  > class A
  > class B extends A
  > class C extends A
  > class D extends multi B, C
  > assert new D not instanceof B

  Instead, one should use the provided *isInstance* function.

- Some of the bases of a multi-inherited hierarchy are *frozen* when
  the sub-class is defined -- i.e. later modifications to the
  superclass are not visible to the subclass or its instances.  For
  example, in the previous heterarchy:

  > B::newProperty = 42
  > assert D::newProperty == undefined

    exports.multi = (bases...) ->
        generate merge [], map(bases, mro).concat [bases]

    copyOwn = (from, to) ->
        for own key, value of from
            if not to.hasOwnProperty key
                to[key] = value
        to

    generate = memoize (linearization) ->
        next = head linearization
        if linearization.equals hierarchy next
            next
        else
            class MultiSuperClass extends generate tail linearization
                __mro__: linearization
            copyOwn next::, MultiSuperClass::
            copyOwn next, MultiSuperClass
            MultiSuperClass

    merge = (result, inputs) ->
        if every inputs, isEmpty
            do result.reverse
        else
            next = find (map inputs, head), (candidate) ->
                every inputs, (input) -> candidate not in tail input
            if next
                merge [next].concat(result), map inputs, (lst) -> without lst, next
            else
                throw new Error("Inconsistent precedence graph.")


Introspection
-------------

The **mro** function returns the method resolution order
(linearization) of a given class:

> class A
> class B extends A
> class C extends B
> assert mro(C).equals [C, B, A]

It returns the original classes that were mixed in when used with
mult-inherited classes:

> class A
> class B extends A
> class C extends A
> class D extends multi B, C
> assert mro(D).equals [D, B, C, A, Object]

    exports.mro = mro = (cls) ->
        if not cls?
            []
        else if not cls::hasOwnProperty '__mro__'
            cls::__mro__ = [cls].concat mro inherited(cls)
        else
            cls::__mro__

The **inherited** function returns the CoffeeScript superclass of an
object, for example:

> class A
> class B extends A
> assert inherited(B) == A

Note that for multiple inherited classes, this returns the mixed
object, not the next class in the MRO, as in:

> class C extends multi A, B
> assert inherited(C) == multi(A, B)

    exports.inherited = inherited = (cls) ->
        Object.getPrototypeOf(cls.prototype)?.constructor

The **hierarchy** returns the CoffeeScript hierarchy of classes of a
given class, including the class itself.  For multiple inherited
classes, it may return speciall classes that were generated to produce
the flattening, as in:

> class A
> class B extends A
> class C extends A
> class D extends multi B, C
> assert not mro(D).equals hierarchy(D)
> assert hierarchy(D).equals
>     [ D, multi(B, C), inherited(multi B, C), A, Object ]

    exports.hierarchy = hierarchy = (cls) ->
        if not cls?
            []
        else
            [cls].concat hierarchy inherited cls

The **isInstance** function takes an object and a class or classes and
returns whether the object is an instance of any of those classes. It
is compatible with multi-inherited classes.

    exports.isInstance = (obj, classes...) ->
        return some classes, (cls) -> obj.constructor in mro cls

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
