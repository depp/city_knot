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


serve:
	webdev serve --verbose web/

presubmit: tests buildall


#@ publish - Update pub.dartlang.org/packages/chronosgl
#@
publish:
	$(PUB) publish

tag:
	git tag $(VERSION) -m "$(VERSION)"
	git show $(VERSION)

#@ documentation - Extract the class_glossary.md files from the source
#@
documentation:
	dart  tool/generate_documentation.dart > class_glossary.md

############################################################
# TESTING
############################################################
# TODO(robertm): vm tests are failing on exit:
# Invalid argument(s): Illegal argument in isolate message : (object is a regular Dart Instance)
start_test_server:
	$(PUB) serve example --web-compiler=dartdevc --port 8111

browser_tests:
	$(PUB) run test  -p chrome --pub-serve=8111 test/geometry.dart

brower_tests_old:
	-$(PUB) run test  -p chrome --pub-serve=8111 test/geometry.dart
	$(PUB) run test   -p dartium test/shader_syntax.dart
	$(PUB) run test   -p dartium test/show_extensions.dart

tests:
	$(PUB) run test   -p vm test/polygon.dart
	$(PUB) run test   -p chrome test/geometry.dart
	$(PUB) run test   -p chrome test/shader_syntax.dart
