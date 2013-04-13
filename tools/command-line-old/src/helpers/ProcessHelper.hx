package helpers;


import haxe.io.Path;
import sys.FileSystem;


class ProcessHelper {
	
	
	public static function openFile (workingDirectory:String, targetPath:String, executable:String = ""):Void {
		
		if (executable == null) { 
			
			executable = "";
			
		}
		
		if (InstallTool.isWindows) {
			
			if (executable == "") {
				
				if (targetPath.indexOf (":\\") == -1) {
					
					runCommand (workingDirectory, targetPath, []);
					
				} else {
					
					runCommand (workingDirectory, ".\\" + targetPath, []);
					
				}
				
			} else {
				
				if (targetPath.indexOf (":\\") == -1) {
					
					runCommand (workingDirectory, executable, [ targetPath ]);
					
				} else {
					
					runCommand (workingDirectory, executable, [ ".\\" + targetPath ]);
					
				}
				
			}
			
		} else if (InstallTool.isMac) {
			
			if (executable == "") {
				
				executable = "open";
				
			}
			
			if (targetPath.substr (0) == "/") {
				
				runCommand (workingDirectory, executable, [ targetPath ]);
				
			} else {
				
				runCommand (workingDirectory, executable, [ "./" + targetPath ]);
				
			}
			
		} else {
			
			if (executable == "") {
				
				executable = "xdg-open";
				
			}
			
			if (targetPath.substr (0) == "/") {
				
				runCommand (workingDirectory, executable, [ targetPath ]);
				
			} else {
				
				runCommand (workingDirectory, executable, [ "./" + targetPath ]);
				
			}
			
		}
		
	}
	
	
	public static function openURL (url:String):Void {
		
		if (InstallTool.isWindows) {
			
			runCommand ("", url, []);
			
		} else if (InstallTool.isMac) {
			
			runCommand ("", "open", [ url ]);
			
		} else {
			
			runCommand ("", "xdg-open", [ url ]);
			
		}
		
	}
	
	
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
