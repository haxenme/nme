package installers;


import data.Asset;
import neko.io.Path;
import neko.io.Process;
import neko.FileSystem;
import neko.Lib;
import neko.Sys;


class AndroidInstaller extends buildhx.installers.AndroidInstaller {
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/android/bin/";
		mkdir (destination);
		
		var packageDirectory:String = defines.get ("APP_PACKAGE");
		packageDirectory = destination + "/src/" + packageDirectory.split (".").join ("/");
		mkdir (packageDirectory);
		
		generateSWFClasses (buildDirectory + "/android/haxe");
		
		super.update ();
		
	}
	
	
}
