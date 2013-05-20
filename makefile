#
#  File:       nanokontrol2.coffee
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#  Date:       Mon May 20 15:27:56 2013
#
#  Generates proper Mixxx script configuration files from smart
#  smart CoffeeScript file.
#


all: nanokontrol2.js core.js nanokontrol2.midi.xml

%.js: %.coffee
	coffee -c $<

nanokontrol2.midi.xml: nanokontrol2.coffee
	coffee $^ -g > $@
