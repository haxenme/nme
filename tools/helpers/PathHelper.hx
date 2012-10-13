package;


import sys.io.Process;
import sys.FileSystem;


class PathHelper {
	
	
	public static function combine (firstPath:String, secondPath:String):String {
		
		if (firstPath == null || firstPath == "") {
			
			if (secondPath != null && secondPath.substr (0, 1) == "/" || secondPath.substr (0, 1) == "\\") {
				
				return secondPath.substr (1);
				
			} else {
				
				return secondPath;
				
			}
			
		} else if (secondPath != null && secondPath != "") {
			
			var firstSlash = (firstPath.substr (-1) == "/" || firstPath.substr (-1) == "\\");
			var secondSlash = (secondPath.substr (0, 1) == "/" || secondPath.substr (0, 1) == "\\");
			
			if (firstSlash && secondSlash) {
				
				return firstPath + secondPath.substr (1);
				
			} else if (!firstSlash && !secondSlash) {
				
				return firstPath + "/" + secondPath;
				
			} else {
				
				return firstPath + secondPath;
				
			}
			
		} else {
			
			return firstPath;
			
		}
		
	}
	
	
	public static function escape (path:String):String {
		
		if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
			
			path = StringTools.replace (path, " ", "\\ ");
			
			return expand (path);
			
		}
		
		return expand (path);
		
	}
	
	
	public static function expand (path:String):String {
		
		if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
			
			if (StringTools.startsWith (path, "~/")) {
				
				path = Sys.getEnv ("HOME") + "/" + path.substr (2);
				
			}
			
		}
		
		return path;
		
	}
	
	
	public static function findTemplate (templatePaths:Array <String>, path:String, warnIfNotFound:Bool = true):String {
		
		var found = null;
		
		for (templatePath in templatePaths) {
			
			var targetPath = combine (templatePath, path);
			
			if (FileSystem.exists (targetPath)) {
				
				found = targetPath;
				
			}
			
		}
		
		if (found == null && warnIfNotFound) {
			
			LogHelper.warn ("Could not find template file: " + path);
			
		}
		
		return found;
		
	}
	
	
	public static function getHaxelib (name:String):String {
		
		var proc = new Process ("haxelib", ["path", name ]);
		var result = "";
		
		try {
			
			while (true) {
				
				var line = proc.stdout.readLine ();
				
				if (line.substr (0, 1) != "-") {
					
					result = line;
					break;
					
				}
				
			}
			
		} catch (e:Dynamic) { };
		
		proc.close();
		
		if (result == "") {
			
			LogHelper.error ("Could not find haxelib \"" + name + "\", does it need to be installed?");
			
		} else {
			
			//LogHelper.info ("", " - Discovered haxelib \"" + name + "\" at \"" + result + "\"");
			
		}
		
		return result;
		
	}
	
	
	public static function getLibraryPath (ndll:NDLL, directoryName:String, namePrefix:String = "", nameSuffix:String = ".ndll", allowDebug:Bool = false):String {
		
		var usingDebug = false;
		var path = "";
		
		if (allowDebug) {
			
			path = searchForLibrary (ndll, directoryName, namePrefix + ndll.name + "-debug" + nameSuffix);
			usingDebug = FileSystem.exists (path);
			
		}
		
		if (!usingDebug) {
			
			path = searchForLibrary (ndll, directoryName, namePrefix + ndll.name + nameSuffix);
			
		}
		
		return path;
		
	}
	
	
	public static function isAbsolute (path:String):Bool {
		
		if (StringTools.startsWith (path, "/") || StringTools.startsWith (path, "\\")) {
			
			return true;
			
		}
		
		return false;
		
	}
	
	
	public static function isRelative (path:String):Bool {
		
		return !isAbsolute (path);
		
	}
	
	
	public static function mkdir (directory:String):Void {
		
		directory = StringTools.replace (directory, "\\", "/");
		var total = "";
		
		if (directory.substr (0, 1) == "/") {
			
			total = "/";
			
		}
		
		var parts = directory.split("/");
		var oldPath = "";
		
		if (parts.length > 0 && parts[0].indexOf (":") > -1) {
			
			oldPath = Sys.getCwd ();
			Sys.setCwd (parts[0] + "\\");
			parts.shift ();
			
		}
		
		for (part in parts) {
			
			if (part != "." && part != "") {
				
				if (total != "") {
					
					total += "/";
					
				}
				
				total += part;
				
				if (!FileSystem.exists (total)) {
					
					LogHelper.info ("", " - Creating directory: " + total);
					
					FileSystem.createDirectory (total);
					
				}
				
			}
			
		}
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
	}
	
	
	public static function relocatePath (path:String, targetDirectory:String):String {
		
		// this should be improved for target directories that are outside the current working path
		
		if (isAbsolute (path) || targetDirectory == "") {
			
			return path;
			
		} else if (isAbsolute (targetDirectory)) {
			
			return FileSystem.fullPath (path);
			
		} else {
			
			targetDirectory = StringTools.replace (targetDirectory, "\\", "/");
			var splitTarget = targetDirectory.split ("/");
			var directories = 0;
			
			while (splitTarget.length > 0) {
				
				switch (splitTarget.shift ()) {
					
					case ".":
						
						// ignore
					
					case "..":
						
						directories--;
						
					default:
						
						directories++;
						
				}
				
			}
			
			var adjust = "";
			
			for (i in 0...directories) {
				
				adjust += "../";
				
			}
			
			return adjust + path;
			
		}
		
	}
	
	
	public static function relocatePaths (paths:Array <String>, targetDirectory:String):Array <String> {
		
		var relocatedPaths = paths.copy ();
		
		for (i in 0...paths.length) {
			
			relocatedPaths[i] = relocatePath (paths[i], targetDirectory);
			
		}
		
		return relocatedPaths;
		
	}
	
	
	public static function removeDirectory (directory:String):Void {
		
		if (FileSystem.exists (directory)) {
			
			for (file in FileSystem.readDirectory (directory)) {
				
				var path = directory + "/" + file;
				
				if (FileSystem.isDirectory (path)) {
					
					removeDirectory (path);
					
				} else {
					
					FileSystem.deleteFile (path);
					
				}
				
			}
			
			LogHelper.info ("", " - Removing directory: " + directory);
			
			FileSystem.deleteDirectory (directory);
			
		}
		
	}
	
	
	public static function safeFileName (name:String):String {
		
		var safeName = StringTools.replace (name, " ", "");
		return safeName;
		
	}
	
	
	private static function searchForLibrary (ndll:NDLL, directoryName:String, filename:String):String {
		
		if (ndll.path != null && ndll.path != "") {
			
			return ndll.path;
			
		} /*else if (extension != "" && haxelib == "nme-extension") {
			
			return extension + "/ndll/" + directoryName + "/" + filename;
			
		}*/ else if (ndll.haxelib == "" || ndll.haxelib == "hxcpp") {
			
			var path = getHaxelib ("hxcpp") + "/bin/" + directoryName + "/" + filename;
			
			if (FileSystem.exists (path)) {
				
				return path;
				
			} else {
				
				return filename;
				
			}
			
		} else {
			
			return getHaxelib (ndll.haxelib) + "/ndll/" + directoryName + "/" + filename;
			
		}
		
	}
	
	
	public static function tryFullPath (path:String):String {
		
		try {
			
			return FileSystem.fullPath (path);
			
		} catch (e:Dynamic) {
			
			return expand (path);
			
		}
		
	}
		

}
