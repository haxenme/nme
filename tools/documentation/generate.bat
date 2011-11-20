haxe -xml bin/std-cpp.xml -cpp obj/std-cpp -cp src haxe.ImportAll
haxe -xml bin/std-flash.xml -swf obj/std-flash.swf -swf-version 11 -cp src haxe.ImportAll

:: haxe -xml bin/std-neko.xml -neko obj/std-neko.n -cp src haxe.ImportAll
:: haxe -xml bin/std-js.xml -js obj/std-js.js -cp src haxe.ImportAll

haxe -xml bin/nme-cpp.xml -cpp obj/nme-cpp -cp src nme.ImportAll -D nme_document -lib nme
haxe -xml bin/nme-flash.xml -swf obj/nme-flash.swf -cp src nme.ImportAll -D nme_document -lib nme

:: haxe -xml bin/nme-neko.xml obj/nme-neko.n -cp src nme.ImportAll
:: haxe -xml bin/nme-js.xml obj/nme-js.js -cp src nme.ImportAll

chxdoc -o output/cpp --tmpDir=obj bin/std-cpp.xml,std bin/nme-cpp.xml,nme
chxdoc -o output/flash --tmpDir=obj bin/std-flash.xml,std bin/nme-flash.xml,nme