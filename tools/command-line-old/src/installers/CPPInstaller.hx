package installers;


import haxe.io.Path;
import helpers.FileHelper;
import sys.io.Process;
import neko.Lib;


class CPPInstaller extends DesktopInstaller {


	override function getVM ():String { 
		
		return "cpp";
		
	}
	

	override function copyResultTo (path:String) {
		
		var debugString:String = (debug ? "-debug" : "");
		var extension:String = (targetName=="windows") ? ".exe" : "";
		
		FileHelper.copyIfNewer (getBuildDir() + "/ApplicationMain" + debugString + extension, path);
		
	}
	

	override function generateContext ():Void {
		
		if (targetName == "windows") {
			
			if (!defines.exists ("SHOW_CONSOLE")) {
				
				defines.set ("no_console", "1");
				Sys.putEnv ("no_console", "1");
				
			}
			
			/*if (Sys.environment ().exists ("VS110COMNTOOLS")) {
				
				Lib.println ("Warning: Visual Studio 2012 is not supported. Trying Visual Studio 2010...");
				Sys.putEnv ("VS110COMNTOOLS", Sys.getEnv ("VS100COMNTOOLS"));
				
			}*/
			
		} else if (targetName == "mac") {
			
			Sys.putEnv ("HXCPP_CLANG", "1");
			
		}
		
		super.generateContext ();
		
		context.CPP_DIR = getBuildDir ();
		context.HXML_PATH = templatePaths[0] + "cpp/hxml/" + (debug ? "debug" : "release") + ".hxml";
		
	}
	

}
