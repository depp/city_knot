set -e

build() {
    sed -i '' "s/^const int magicMult = [0-9]+;/const int magicMult = $1;/" web/meshes.dart
    rm -rf build
    make build_release
}

rm -rf City_Knot
mkdir City_Knot
mkdir City_Knot/low_resolution

build 8
cp build/delta.html City_Knot/city_knot.html
cp build/delta.dart.js City_Knot/delta.dart.js
cp web/music.opus City_Knot/music.opus

build 4
cp build/delta.html City_Knot/low_resolution/city_knot.html
cp build/delta.dart.js City_Knot/low_resolution/delta.dart.js
sed -i '' 's#music\.opus#../music.opus#' City_Knot/low_resolution/city_knot.html

rm -f City_Knot.zip
zip City_Knot.zip City_Knot -r -D
