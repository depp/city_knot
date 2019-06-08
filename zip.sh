set -e
rm -rf build
make build_release
cd build
zip CityKnot.zip delta.html delta.dart.js sound.ogg
