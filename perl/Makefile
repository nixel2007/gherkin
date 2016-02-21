GOOD_FEATURE_FILES = $(shell find ../testdata/good -name "*.feature")
BAD_FEATURE_FILES  = $(shell find ../testdata/bad -name "*.feature")

TOKENS   = $(patsubst ../testdata/%.feature,acceptance/testdata/%.feature.tokens,$(GOOD_FEATURE_FILES))
ASTS     = $(patsubst ../testdata/%.feature,acceptance/testdata/%.feature.ast.json,$(GOOD_FEATURE_FILES))
PICKLES  = $(patsubst ../testdata/%.feature,acceptance/testdata/%.feature.pickles.json,$(GOOD_FEATURE_FILES))
ERRORS   = $(patsubst ../testdata/%.feature,acceptance/testdata/%.feature.errors,$(BAD_FEATURE_FILES))

PERL_FILES = $(shell find . -name "*.pm")

all: .compared
.PHONY: all

.compared: .built $(TOKENS) $(ASTS) $(PICKLES) $(ERRORS)
	touch $@

#.built: lib/Gherkin/Generated/Parser.pm gherkin/gherkin-languages.json $(PERL_FILES) bin/gherkin-generate-tokens bin/gherkin-generate-ast LICENSE.txt
# ADD AST BUIL BACK IN
.built: lib/Gherkin/Generated/Parser.pm gherkin/gherkin-languages.json $(PERL_FILES) bin/gherkin-generate-tokens LICENSE.txt
	@$(MAKE) --no-print-directory show-version-info
	#nosetests
	touch $@

show-version-info:
	perl --version
.PHONY: show-version-info

acceptance/testdata/%.feature.tokens: ../testdata/%.feature ../testdata/%.feature.tokens .built
	mkdir -p `dirname $@`
	bin/gherkin-generate-tokens $< > $@
	diff --unified $<.tokens $@
.DELETE_ON_ERROR: acceptance/testdata/%.feature.tokens

acceptance/testdata/%.feature.ast.json: ../testdata/%.feature ../testdata/%.feature.ast.json .built
	mkdir -p `dirname $@`
	bin/gherkin-generate-ast $< > $@
	diff --unified $<.ast.json $@
.DELETE_ON_ERROR: acceptance/testdata/%.feature.ast.json

acceptance/testdata/%.feature.pickles.json: ../testdata/%.feature ../testdata/%.feature.pickles.json .built
	mkdir -p `dirname $@`
	bin/gherkin-generate-pickles $< > $@
	diff --unified $<.pickles.json $@
.DELETE_ON_ERROR: acceptance/testdata/%.feature.pickles.json

acceptance/testdata/%.feature.errors: ../testdata/%.feature ../testdata/%.feature.errors .built
	mkdir -p `dirname $@`
	! bin/gherkin-generate-ast $< 2> $@
	diff --unified $<.errors $@
.DELETE_ON_ERROR: acceptance/testdata/%.feature.errors

gherkin/gherkin-languages.json: ../gherkin-languages.json
	cp $^ $@

clean:
	rm -rf .compared .built acceptance gherkin/parser.py gherkin/gherkin-languages.json
.PHONY: clean

lib/Gherkin/Generated/Parser.pm: ../gherkin.berp gherkin-perl.razor ../bin/berp.exe
	mono ../bin/berp.exe -g ../gherkin.berp -t gherkin-perl.razor -o $@
	# Remove BOM
	tail -c +4 $@ > $@.nobom
	mv $@.nobom $@

LICENSE.txt: ../LICENSE
	cp $< $@

update-gherkin-languages: gherkin/gherkin-languages.json
.PHONY: update-gherkin-languages