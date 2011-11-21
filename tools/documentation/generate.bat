haxe -xml bin/cpp.xml -cpp obj/cpp -cp src haxe.ImportAll
haxe -xml bin/flash.xml -swf obj/flash.swf -cp src haxe.ImportAll

haxe -xml bin/neko.xml -neko obj/neko.n -cp src haxe.ImportAll
haxe -xml bin/js.xml -js obj/js.js -cp src haxe.ImportAll

haxe -xml bin/nme.xml -cpp obj/nme -cp src nme.ImportAll -D nme_document -lib nme
:: haxe -xml bin/nme-flash.xml -swf obj/nme-flash.swf -cp src nme.ImportAll -D nme_document -lib nme

chxdoc -o output --tmpDir=obj --xmlBasePath=bin cpp.xml,cpp flash.xml,flash neko.xml,neko js.xml,js nme.xml,nme --title="NME API Documentation" --subtitle="http://www.haxenme.org"