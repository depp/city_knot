export PATH := $(PATH):$(HOME)/.pub-cache/bin:.

.PHONY=documentation examples tests presubmit buildall

PUB=/usr/lib/dart/bin/pub

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


#@ serve - Launch web server (also does just-in-time-transpiling)
#@         Uses the development compiler.
#@         go to localhost:8080/delta.html
#@
serve:
	webdev serve --verbose web/


#@ build_release - builds a release version using dart2js
#@                 Output can be found in build/
#@
build_release:
	webdev build --verbose --release --output web:build

#@ serve_release - launch web server for what is generated by
#@          	`build_release`
#@ 
serve_release:
	python3 -m http.server 8080

