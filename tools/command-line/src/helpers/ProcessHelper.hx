package helpers;


import haxe.io.Path;
import sys.FileSystem;


class ProcessHelper {
	
	
	public static function runCommand (path:String, command:String, args:Array <String>, safeExecute:Bool = true, ignoreErrors:Bool = false):Void {
		
		if (safeExecute) {
			
			try {
				
				if (path != "" && !FileSystem.exists (FileSystem.fullPath (new Path (path).dir))) {
					
					InstallTool.error ("The specified target path \"" + path + "\" does not exist");
					
				}
				
				_runCommand (path, command, args);
				
			} catch (e:Dynamic) {
				
				if (!ignoreErrors) {
					
					InstallTool.error ("", e);
					
				}
				
			}
			
		} else {
			
			_runCommand (path, command, args);
			
		}
	  
	}
	
	
	private static function _runCommand (path:String, command:String, args:Array<String>) {
		
		var oldPath:String = "";
		
		if (path != "") {
			
			InstallTool.print("cd " + path);
			
			oldPath = Sys.getCwd ();
			Sys.setCwd (path);
			
		}
		
		InstallTool.print(command + (args==null ? "": " " + args.join(" ")) );
		
		var result:Dynamic = Sys.command (command, args);
		
		if (result == 0)
			InstallTool.print("Ok.");
			
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
		if (result != 0) {
			
			throw ("Error running: " + command + " " + args.join (" ") + " [" + path + "]");
			
		}
		
	}
		

}
