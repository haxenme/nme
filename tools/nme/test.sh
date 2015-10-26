set -e
haxe compile.hxml
haxe test.hxml
neko bin/TestMain.n