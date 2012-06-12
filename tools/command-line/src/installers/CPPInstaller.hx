package installers;


import neko.io.Path;
import neko.io.Process;
import neko.Lib;
import neko.Sys;


class CPPInstaller extends DesktopInstaller {


	override function getVM ():String { 
		
		return "cpp";
		
	}
	

	override function copyResultTo (path:String) {
		
		var debugString:String = (debug ? "-debug" : "");
		var extension:String = (targetName=="windows") ? ".exe" : "";
		
		copyIfNewer (getBuildDir() + "/ApplicationMain" + debugString + extension, path);
		
	}
	

	override function generateContext ():Void {
		
		if (targetName == "windows") {
			
			if (!defines.exists ("SHOW_CONSOLE") && (!debug || defines.exists ("HIDE_CONSOLE"))) {
				
				defines.set ("no_console", "1");
				Sys.putEnv ("no_console", "1");
				
			}
			
		}
		
		super.generateContext ();
		
		context.CPP_DIR = getBuildDir ();
		context.HXML_PATH = NME + "/tools/command-line/cpp/hxml/" + (debug ? "debug" : "release") + ".hxml";
		
	}
	

}
