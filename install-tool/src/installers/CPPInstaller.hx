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
		
		if (targetName == "windows") {
			
			setWindowsEnvironment ();
			
		}
		
	}
	
	
	private function setWindowsEnvironment ():Void {
		
		var importProcess:Process = new Process ("cmd.exe", [ "/C", nme + "/install-tool/windows/msvc.bat" ]);
		var foundVariables:Bool = false;
		
		try {
			
			while (true) {
				
				var string:String = importProcess.stdout.readLine ();
				
				if (string == "HXCPP_VARS") {
					
					foundVariables = true;
					
				}
				
				if (foundVariables) {
					
					if (InstallTool.verbose) {
						
						Lib.println (string);
						
					}
					
					var indexOfEquals:Int = string.indexOf ("=");
					var name:String = string.substr (0, indexOfEquals);
					
					switch (name.toLowerCase ()) {
						
						case "path", "vcinstalldir", "windowssdkdir", "framework35version", "frameworkdir", "frameworkdir32", "frameworkversion", "frameworkversion32", "devenvdir", "include", "lib", "libpath":
							
							var value:String = string.substr (indexOfEquals + 1);
							
							//defines.set (name, value);
							Sys.putEnv (name, value);
						
					}
					
				}
				
			}
			
		} catch (e:Dynamic) { };
		
	}


}
