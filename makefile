#
#  File:       makefile
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#  Date:       Mon May 20 15:27:56 2013
#
#  Generates proper Mixxx script configuration files from smart
#  smart CoffeeScript file.
#


SCRIPTS   = \
	out/korg_nanokontrol2.js out/korg_nanokontrol2.midi.xml \
	out/maudio_xponent.js    out/maudio_xponent.midi.xml \
	out/novation_twitch.js   out/novation_twitch.midi.xml

FRAMEWORK = \
	tmp/mixco/behaviour.js \
	tmp/mixco/control.js \
	tmp/mixco/multi.js \
	tmp/mixco/script.js \
	tmp/mixco/transform.js \
	tmp/mixco/util.js \
	tmp/mixco/value.js

DOCS      = \
	doc/index.html \
	doc/mixco/behaviour.html \
	doc/mixco/control.html \
	doc/mixco/multi.html \
	doc/mixco/script.html \
	doc/mixco/transform.html \
	doc/mixco/util.html \
	doc/mixco/value.html \
	doc/script/korg_nanokontrol2.html \
	doc/script/maudio_xponent.html \
	doc/script/novation_twitch.html \
	doc/spec/mixco/behaviour.spec.html \
	doc/spec/mixco/control.spec.html \
	doc/spec/mixco/multi.spec.html \
	doc/spec/mixco/script.spec.html \
	doc/spec/mixco/value.spec.html \
	doc/spec/mock.html \
	doc/spec/scripts.spec.html

all: $(SCRIPTS)

framework: $(FRAMEWORK)

doc: $(DOCS)
	cp -r ./pic ./doc/

.SECONDARY:

NODE       = node
COFFEE     = coffee
BROWSERIFY = browserify
DOCCO      = docco

tmp/%.js: %.litcoffee
	@mkdir -p $(@D)
	coffee -c -p $< > $@

tmp/%.js: %.js
	@mkdir -p $(@D)
	cp -f $< $@

out/%.js: tmp/script/%.js $(FRAMEWORK)
	@echo
	@echo \*\*\* Building $* JS script file
	@echo
	@mkdir -p $(@D)
	$(BROWSERIFY) -r ./$< $< > $@
	echo ";$*=require('./$<').$*" >> $@

out/%.midi.xml: script/%.litcoffee $(FRAMEWORK)
	@echo
	@echo \*\*\* Building $* XML mapping file
	@echo
	@mkdir -p $(@D)
	coffee $< -g > $@

out/%.midi.xml: tmp/script/%.js $(FRAMEWORK)
	@echo
	@echo \*\*\* Building $* XML mapping file
	@echo
	@mkdir -p $(@D)
	node $< -g > $@

doc/index.html: README.md
	@mkdir -p $(@D)
	$(DOCCO) -t docco/docco.jst -c docco/docco.css  -o $(@D) $<
	mv $(@D)/README.html $@
	cp -rf docco/public $(@D)

doc/%.html: %.litcoffee
	@mkdir -p $(@D)
	$(DOCCO) -t docco/docco.jst -c docco/docco.css -o $(@D) $<
	cp -rf docco/public $(@D)

doc/%.html: %.js
	@mkdir -p $(@D)
	$(DOCCO) -t docco/docco.jst -c docco/docco.css -o $(@D) $<
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
