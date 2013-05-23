#
#  File:       nanokontrol2.coffee
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#  Date:       Mon May 20 15:27:56 2013
#
#  Generates proper Mixxx script configuration files from smart
#  smart CoffeeScript file.
#


SCRIPTS    = out/nanokontrol2.js out/nanokontrol2.midi.xml
FRAMEWORK  = \
	tmp/mixco/util.js \
	tmp/mixco/transform.js \
	tmp/mixco/script.js \
	tmp/mixco/control.js


all: $(SCRIPTS)

.SECONDARY:

tmp/%.js: %.coffee
	@mkdir -p $(@D)
	coffee -c -p $< > $@

out/%.js: tmp/script/%.js $(FRAMEWORK)
	@echo
	@echo \*\*\* Building $* JS script file
	@echo
	@mkdir -p $(@D)
	browserify -r ./$< $< > $@
	echo ";$*=require('./$<').$*" >> $@

out/%.midi.xml: script/%.coffee $(FRAMEWORK)
	@echo
	@echo \*\*\* Building $* XML mapping file
	@echo
	@mkdir -p $(@D)
	coffee $< -g > $@

clean:
	rm -rf ./out
	rm -rf ./tmp
	find . -name "*~" -exec rm -f {} \;
