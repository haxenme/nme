package installers;


import neko.io.Path;
import neko.io.Process;
import neko.FileSystem;
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
		
		super.generateContext ();
		
		context.CPP_DIR = getBuildDir ();
		
	}
	

}
