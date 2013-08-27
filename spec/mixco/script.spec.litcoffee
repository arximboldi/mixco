spec.mixco.value
================

Tests for the `mixco.value` module.

Module
------

    {Script} = require '../../mixco/script'


Mocks
-----

    class TestScript extends Script

Tests
-----

    describe 'Script', ->

        script = null

        beforeEach ->
            script = new TestScript

        it 'configures controller id to be de script name', ->
            expect(script.config())
                .toMatch "<controller id=\"testscript\">[^$]*</controller>"

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
