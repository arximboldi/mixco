#
#  File:       nanokontrol2.coffee
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#  Date:       Mon May 20 15:27:56 2013
#
#  Generates proper Mixxx script configuration files from smart
#  smart CoffeeScript file.
#


SCRIPTS = nanokontrol2.js nanokontrol2.midi.xml
FRAMEWORK = core.nodejs

all: $(SCRIPTS)

%.nodejs: %.coffee
	coffee -c -p $< > $@

%.js: %.nodejs $(FRAMEWORK)
	browserify -r ./$< $< > $@
	echo ";$*=require('./$<').$*" >> $@

%.midi.xml: %.coffee $(FRAMEWORK)
	coffee $^ -g > $@
