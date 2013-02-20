package installers;


import haxe.io.Path;
import sys.io.Process;
import neko.Lib;
import Sys;


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
		context.HXML_PATH = NME + "/tools/command-line-simple/cpp/hxml/" + (debug ? "debug" : "release") + ".hxml";
		
	}
	

}
