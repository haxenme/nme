
How to Build
------------


Copy the files for haXe and Neko into the resource folders:

	./resources/haxe
	./resources/neko


Then copy the files for NME, HXCPP, Jeash and Actuate. These should retain their versioned folder names from haxelib.

For example:
	
	./resources/actuate/1,38
	./resources/hxcpp/2,08,0
	./resources/jeash/0,8,7
	./resources/nme/3,1,1


The installer is built using the Nullsoft Scriptable Install System. You can download the newest version, here:

	http://nsis.sourceforge.net/Download


Open "Installer.nsi" and build!




Tips for Improvement
--------------------


The script is based on the one from FlashDevelop. If you want to add more functionality, looking at that script first is a great example, and perfect for copy-and-paste :)

	http://code.google.com/p/flashdevelop/source/browse/trunk/FD4/FlashDevelop/Installer/Installer.nsi 