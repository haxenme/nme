package;


import haxe.io.Path;
import sys.FileSystem;


class ProcessHelper {
	
	private static inline var OPEN:String = "/usr/bin/open";
	private static inline var XDG_OPEN:String = "/usr/bin/xdg-open";

	public static function openFile (workingDirectory:String, targetPath:String, executable:String = ""):Void {
		
		if (executable == null) { 
			
			executable = "";
			
		}
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
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
			
		} else if (PlatformHelper.hostPlatform == Platform.MAC) {
			
			if (executable == "") {
				
				executable = OPEN;
				
			}
			
			if (targetPath.substr (0) == "/") {
				
				runCommand (workingDirectory, executable, [ targetPath ]);
				
			} else {
				
				runCommand (workingDirectory, executable, [ "./" + targetPath ]);
				
			}
			
		} else {
			
			if (executable == "") {
				
				executable = XDG_OPEN;
				
			}
			
			if (targetPath.substr (0) == "/") {
				
				runCommand (workingDirectory, executable, [ targetPath ]);
				
			} else {
				
				runCommand (workingDirectory, executable, [ "./" + targetPath ]);
				
			}
			
		}
		
	}
	
	
	public static function openURL (url:String):Void {
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			runCommand ("", url, []);
			
		} else if (PlatformHelper.hostPlatform == Platform.MAC) {
			
			runCommand ("", OPEN, [ url ]);
			
		} else {
			
			runCommand ("", XDG_OPEN, [ url ]);
			
		}
		
	}
	
	
	public static function runCommand (path:String, command:String, args:Array <String>, safeExecute:Bool = true, ignoreErrors:Bool = false):Void {
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			command = StringTools.replace (command, ",", "^,");
			
		}
		
		if (safeExecute) {
			
			try {
				
				if (path != "" && !FileSystem.exists (FileSystem.fullPath (path)) && !FileSystem.exists (FileSystem.fullPath (new Path (path).dir))) {
					
					LogHelper.error ("The specified target path \"" + path + "\" does not exist");
					
				}
				
				_runCommand (path, command, args);
				
			} catch (e:Dynamic) {
				
				if (!ignoreErrors) {
					
					LogHelper.error ("", e);
					
				}
				
			}
			
		} else {
			
			_runCommand (path, command, args);
			
		}
	  
	}
	
	
	private static function _runCommand (path:String, command:String, args:Array<String>) {
		
		var oldPath:String = "";
		
		if (path != "") {
			
			LogHelper.info ("", " - Changing directory: " + path + "");
			
			oldPath = Sys.getCwd ();
			Sys.setCwd (path);
			
		}
		
		var argString = "";
		
		for (arg in args) {
			
			if (arg.indexOf (" ") > -1) {
				
				argString += " \"" + arg + "\"";
				
			} else {
				
				argString += " " + arg;
				
			}
			
		}
		
		LogHelper.info ("", " - Running command: " + command + argString);
		
		var result:Dynamic = Sys.command (command, args);
		
		if (result == 0) {
			
			//LogHelper.info("", "(Done)");
			
		}
			
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
		if (result != 0) {
			
			throw ("Error running: " + command + " " + args.join (" ") + " [" + path + "]");
			
		}
		
	}
		

}
