#
#  File:       makefile
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#  Date:       Mon May 20 15:27:56 2013
#
#  Generates proper Mixxx script configuration files from smart
#  smart CoffeeScript file.
#


SCRIPTS   = \
	out/nanokontrol2.js out/nanokontrol2.midi.xml

FRAMEWORK = \
	tmp/mixco/util.js \
	tmp/mixco/transform.js \
	tmp/mixco/script.js \
	tmp/mixco/control.js \
	tmp/mixco/behaviour.js

DOCS      = \
	doc/index.html \
	doc/script/nanokontrol2.html \
	doc/mixco/control.html \
	doc/mixco/script.html \
	doc/mixco/util.html \
	doc/mixco/transform.html \
	doc/mixco/behaviour.html

all: $(SCRIPTS)

doc: $(DOCS)
	cp -r ./pic ./doc/

.SECONDARY:

tmp/%.js: %.litcoffee
	@mkdir -p $(@D)
	coffee -c -p $< > $@

out/%.js: tmp/script/%.js $(FRAMEWORK)
	@echo
	@echo \*\*\* Building $* JS script file
	@echo
	@mkdir -p $(@D)
	browserify -r ./$< $< > $@
	echo ";$*=require('./$<').$*" >> $@

out/%.midi.xml: script/%.litcoffee $(FRAMEWORK)
	@echo
	@echo \*\*\* Building $* XML mapping file
	@echo
	@mkdir -p $(@D)
	coffee $< -g > $@

doc/index.html: README.md
	@mkdir -p $(@D)
	docco -l linear -o $(@D) $<
	mv $(@D)/README.html $@

doc/%.html: %.litcoffee
	@mkdir -p $(@D)
	docco -l linear -o $(@D) $<

clean:
	rm -rf ./doc
	rm -rf ./out
	rm -rf ./tmp
	find . -name "*~" -exec rm -f {} \;

upload-doc: doc
	ncftpput -R -m -u u48595320 sinusoid.es /mixco doc/*
