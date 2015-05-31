#
#  File:       makefile
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#
#  Generates proper Mixxx script configuration files from smart
#  smart CoffeeScript file.
#

NODE_BIN   = node_modules/.bin

WITH_PATH  = NODE_PATH="$(NODE_PATH):.."
NODEJS     = $(WITH_PATH) node
COFFEE     = $(WITH_PATH) $(NODE_BIN)/coffee
BROWSERIFY = $(WITH_PATH) $(NODE_BIN)/browserify
DOCCO      = $(WITH_PATH) $(NODE_BIN)/docco
MOCHA      = $(WITH_PATH) $(NODE_BIN)/mocha
ISTANBUL   = $(WITH_PATH) $(NODE_BIN)/istanbul
_MOCHA     = $(NODE_BIN)/_mocha

SCRIPTS    = \
	out/korg_nanokontrol2.js out/korg_nanokontrol2.midi.xml \
	out/maudio_xponent.js    out/maudio_xponent.midi.xml \
	out/novation_twitch.js   out/novation_twitch.midi.xml

FRAMEWORK  = \
	lib/behaviour.js \
	lib/cli.js \
	lib/console.js \
	lib/control.js \
	lib/script.js \
	lib/transform.js \
	lib/util.js \
	lib/value.js

DOCS       = \
	doc/index.html \
	doc/src/behaviour.html \
	doc/src/cli.html \
	doc/src/control.html \
	doc/src/console.html \
	doc/src/script.html \
	doc/src/transform.html \
	doc/src/util.html \
	doc/src/value.html \
	doc/script/korg_nanokontrol2.html \
	doc/script/maudio_xponent.html \
	doc/script/novation_twitch.html \
	doc/spec/mixco/behaviour.spec.html \
	doc/spec/mixco/control.spec.html \
	doc/spec/mixco/script.spec.html \
	doc/spec/mixco/value.spec.html \
	doc/spec/mock.html \
	doc/spec/scripts.spec.html

framework: $(FRAMEWORK)

scripts: $(SCRIPTS)

doc: $(DOCS)
	cp -r ./pic ./doc/

.SECONDARY:
.PHONY: test

lib/%.js: src/%.litcoffee
	@mkdir -p $(@D)
	$(COFFEE) -c -p $< > $@
lib/%.js: src/%.coffee
	@mkdir -p $(@D)
	$(COFFEE) -c -p $< > $@
lib/%.js: src/%.js
	@mkdir -p $(@D)
	cp -f $< $@

tmp/%.js: script/%.litcoffee
	@mkdir -p $(@D)
	$(COFFEE) -c -p $< > $@
tmp/%.js: script/%.coffee
	@mkdir -p $(@D)
	$(COFFEE) -c -p $< > $@
tmp/%.js: script/%.js
	@mkdir -p $(@D)
	cp -f $< $@

# $1: input mixco script
# $2: output folder
# $3: script name
define GENERATE_SCRIPT
	@mkdir -p $2
	@mkdir -p tmp
	echo "require('../$1')" >> tmp/$3.entry.js
	$(BROWSERIFY) -u "src/*" -u "coffee-script/register" \
		-t coffeeify --extension=".js" --extension=".coffee" --extension=".litcoffee" \
		-r "./$1:$3" tmp/$3.entry.js -o $2/$3.js
	echo ";$3=require('$3').$3" >> $2/$3.js
endef

out/%.js: script/%.js $(FRAMEWORK)
	$(call GENERATE_SCRIPT,$<,$(@D),$*)
out/%.js: script/%.litcoffee $(FRAMEWORK)
	$(call GENERATE_SCRIPT,$<,$(@D),$*)
out/%.js: script/%.coffee $(FRAMEWORK)
	$(call GENERATE_SCRIPT,$<,$(@D),$*)

out/%.midi.xml: script/%.litcoffee $(FRAMEWORK)
	@mkdir -p $(@D)
	$(COFFEE) $< -g > $@
out/%.midi.xml: script/%.coffee $(FRAMEWORK)
	@mkdir -p $(@D)
	$(COFFEE) $< -g > $@
out/%.midi.xml: script/%.js $(FRAMEWORK)
	@mkdir -p $(@D)
	$(NODEJS) $< -g > $@

doc/index.html: README.md
	@mkdir -p $(@D)
	$(DOCCO) -t docco/docco.jst -c docco/docco.css  -o $(@D) $<
	mv $(@D)/README.html $@
	cp -rf docco/public $(@D)

# $1: input file
# $2: target directory
define GENERATE_DOC
	@mkdir -p $2
	$(DOCCO) -t docco/docco.jst -c docco/docco.css -o $2 $1
	cp -rf docco/public $2
endef

doc/%.html: %.litcoffee
	$(call GENERATE_DOC,$<,$(@D))
doc/%.html: %.coffee
	$(call GENERATE_DOC,$<,$(@D))
doc/%.html: %.js
	$(call GENERATE_DOC,$<,$(@D))

clean:
	rm -rf ./doc
	rm -rf ./out
	rm -rf ./tmp
	rm -rf ./lib
	find . -name "*~" -exec rm -f {} \;

install:
	npm install

test:
	MIXCO_USE_SOURCE=1 \
	$(MOCHA) --recursive --compilers coffee:coffee-script/register

test-coverage:
	MIXCO_USE_SOURCE=1 \
	$(ISTANBUL) cover $(_MOCHA) -- \
		--recursive --compilers coffee:coffee-script/register \
		--require coffee-coverage/register-istanbul
	$(ISTANBUL) report text lcov

upload-doc: doc
	ncftpput -R -m -u u48595320 sinusoid.es /mixco doc/*
