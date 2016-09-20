#
#  File:       makefile
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#
#  Generates proper Mixxx script configuration files from smart
#  smart CoffeeScript file.
#

WITH_PATH  = NODE_PATH="$(NODE_PATH):.."
MIXCO      = $(WITH_PATH) ./bin/mixco.js
_MIXCO     = ./bin/mixco.js

NODE_BIN   = node_modules/.bin
NODEJS     = $(WITH_PATH) node
COFFEE     = $(WITH_PATH) $(NODE_BIN)/coffee
BROWSERIFY = $(WITH_PATH) $(NODE_BIN)/browserify
DOCCO      = $(WITH_PATH) $(NODE_BIN)/docco
MOCHA      = $(WITH_PATH) $(NODE_BIN)/mocha
ISTANBUL   = $(WITH_PATH) $(NODE_BIN)/istanbul
_MOCHA     = $(NODE_BIN)/_mocha

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
	doc/script/korg_nanokontrol2.mixco.html \
	doc/script/maudio_xponent.mixco.html \
	doc/script/novation_twitch.mixco.html \
	doc/test/mixco/behaviour.spec.html \
	doc/test/mixco/control.spec.html \
	doc/test/mixco/script.spec.html \
	doc/test/mixco/value.spec.html \
	doc/test/mock.html \
	doc/test/scripts.spec.html

framework: $(FRAMEWORK)

script: $(FRAMEWORK)
	$(MIXCO) --factory

doc: $(DOCS)
	cp -r ./pic ./doc/

install:
	npm install

test: $(FRAMEWORK)
	MIXCO_USE_SOURCE=1 $(MIXCO) -tT --factory

test-coverage: $(FRAMEWORK)
	MIXCO_COVERAGE=1 MIXCO_USE_SOURCE=1 \
		$(ISTANBUL) cover $(_MIXCO) -- -tT --factory --fatal-tests
	$(ISTANBUL) report text lcov

upload-doc: doc
	ncftpput -R -m -u u48595320 sinusoid.es /mixco doc/*

clean:
	rm -rf ./doc
	rm -rf ./out
	rm -rf ./tmp
	rm -rf ./lib
	rm -rf ./coverage
	rm -rf ./mixco-output
	find . -name "*~" -exec rm -f {} \;

.SECONDARY:
.PHONY: test script clean

lib/%.js: src/%.litcoffee
	@mkdir -p $(@D)
	$(COFFEE) -c -p $< > $@
lib/%.js: src/%.coffee
	@mkdir -p $(@D)
	$(COFFEE) -c -p $< > $@
lib/%.js: src/%.js
	@mkdir -p $(@D)
	cp -f $< $@

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
