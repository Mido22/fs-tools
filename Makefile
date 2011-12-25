PATH        := ./node_modules/.bin:${PATH}

PROJECT     :=  $(notdir ${PWD})
TMP_PATH    := /tmp/${PROJECT}-$(shell date +%s)

REMOTE_NAME ?= origin
REMOTE_REPO ?= $(shell git config --get remote.${REMOTE_NAME}.url)

CURR_HEAD 	:= $(firstword $(shell git show-ref --hash HEAD | cut --bytes=-6) master)
GITHUB_NAME := nodeca/fs-tools
SRC_URL_FMT := https://github.com/${GITHUB_NAME}/blob/${CURR_HEAD}/{file}\#L{line}

JS_FILES    := $(shell find ./bin ./lib ./test -type f -name '*.js' -print)


lint:
	@if test ! `which jslint` ; then \
		echo "You need 'jslint' installed in order to run lint." >&2 ; \
		echo "  $ make dev-deps" >&2 ; \
		exit 128 ; \
		fi
	# (node)    -> Node.JS compatibility mode
	# (indent)  -> indentation level (2 spaces)
	# (nomen)   -> tolerate underscores in identifiers (e.g. `var _val = 1`)
	jslint --node --nomen --indent=2 ./index.js ${JS_FILES}

test: lint
	@if test ! `which vows` ; then \
		echo "You need 'vows' installed in order to run tests." >&2 ; \
		echo "  $ make dev-deps" >&2 ; \
		exit 128 ; \
	fi
	rm -rf ./tmp/sandbox && mkdir -p ./tmp/sandbox
	cp -r ./support/sandbox-template ./tmp/sandbox/copy
	cp -r ./support/sandbox-template ./tmp/sandbox/mkdir
	cp -r ./support/sandbox-template ./tmp/sandbox/remove
	cp -r ./support/sandbox-template ./tmp/sandbox/walk
	NODE_ENV=test vows --spec

doc:
	@if test ! `which ndoc` ; then \
		echo "You need 'ndoc' installed in order to generate docs." >&2 ; \
		echo "  $ npm install -g ndoc" >&2 ; \
		exit 128 ; \
		fi
	rm -rf ./doc
	ndoc --output ./doc --linkFormat "${SRC_URL_FMT}" ./lib

dev-deps:
	@if test ! `which npm` ; then \
		echo "You need 'npm' installed." >&2 ; \
		echo "  See: http://npmjs.org/" >&2 ; \
		exit 128 ; \
		fi
	npm install --dev

gh-pages:
	@if test -z ${REMOTE_REPO} ; then \
		echo 'Remote repo URL not found' >&2 ; \
		exit 128 ; \
		fi
	$(MAKE) doc && \
		cp -r ./doc ${TMP_PATH} && \
		touch ${TMP_PATH}/.nojekyll
	cd ${TMP_PATH} && \
		git init && \
		git add . && \
		git commit -q -m 'Recreated docs'
	cd ${TMP_PATH} && \
		git remote add remote ${REMOTE_REPO} && \
		git push --force remote +master:gh-pages 
	rm -rf ${TMP_PATH}

todo:
	grep 'TODO' -n -r ./lib 2>/dev/null || test true


.PHONY: sandbox test doc dev-deps gh-pages todo
.SILENT: sandbox test doc todo
