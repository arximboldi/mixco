#
#  File:       makefile
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#  Date:       Mon May 20 15:27:56 2013
#
#  Generates proper Mixxx script configuration files from smart
#  smart CoffeeScript file.
#


SCRIPTS   = \
	out/nanokontrol2.js out/nanokontrol2.midi.xml \
	out/xponent.js out/xponent.midi.xml

FRAMEWORK = \
	tmp/mixco/util.js \
	tmp/mixco/transform.js \
	tmp/mixco/script.js \
	tmp/mixco/control.js \
	tmp/mixco/behaviour.js \
	tmp/mixco/value.js

DOCS      = \
	doc/index.html \
	doc/script/nanokontrol2.html \
	doc/script/xponent.html \
	doc/mixco/control.html \
	doc/mixco/script.html \
	doc/mixco/util.html \
	doc/mixco/transform.html \
	doc/mixco/behaviour.html \
	doc/mixco/value.html \
	doc/spec/mock.html \
	doc/spec/scripts.spec.html \
	doc/spec/mixco/behaviour.spec.html \
	doc/spec/mixco/control.spec.html \
	doc/spec/mixco/value.spec.html \
	doc/spec/mixco/script.spec.html

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
	docco -t docco/docco.jst -c docco/docco.css  -o $(@D) $<
	mv $(@D)/README.html $@
	cp -rf docco/public $(@D)

doc/%.html: %.litcoffee
	@mkdir -p $(@D)
	docco -t docco/docco.jst -c docco/docco.css -o $(@D) $<
	cp -rf docco/public $(@D)

clean:
	rm -rf ./doc
	rm -rf ./out
	rm -rf ./tmp
	find . -name "*~" -exec rm -f {} \;

upload-doc: doc
	ncftpput -R -m -u u48595320 sinusoid.es /mixco doc/*

test:
	jasmine-node --verbose --coffee spec
