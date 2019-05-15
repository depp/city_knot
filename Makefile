export PATH := $(PATH):$(HOME)/.pub-cache/bin:.

.PHONY=documentation examples tests presubmit buildall

PUB=/usr/lib/dart/bin/pub
PORT=8000

VERSION := $(shell grep version pubspec.yaml | cut -f 2 -d\ )
#@ Available Targets:
#@

#@ help - Show this messsage
#@
help:
	@egrep "^#@" ${MAKEFILE_LIST} | cut -c 3-

#@ get - Download package dependencies and install tools
#@       (needs to be run at lease once after `git clone`
#@
get:
	$(PUB) get
	${PUB} global activate webdev

#@ examples - Build (release mode) all the examples into build_example/
#@
buildall:
	webdev build --verbose --release --output web:build

#@ serve - Launch web server (also does just-in-time-transpiling)
#@         default port is 8080
#@
serve:
	webdev serve --verbose web/

presubmit: tests buildall


