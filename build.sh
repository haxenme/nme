set -e
cd tools/nme
haxe compile.hxml
cd ../../project
neko Build.n $@
cd ../..