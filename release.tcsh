rm -rf release release.zip
mkdir release
cp -R LICENSE.txt haxelib.xml changes.txt ndll nme project samples release
find release -name .svn -exec rm -rf {} \;
c:/Program\ Files/7-Zip/7z.exe a -tzip release.zip release
#rm -rf release
#haxelib submit release.zip
#pause
