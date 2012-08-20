package helpers;


import sys.FileSystem;
import neko.Lib;


class PathHelper {
	
	
	public static function escape (path:String):String {
		
		if (!InstallTool.isWindows) {
			
			path = StringTools.replace (path, " ", "\\ ");
			
			return expand (path);
			
		}
		
		return expand (path);
		
	}
	
	
	public static function expand (path:String):String {
		
		if (!InstallTool.isWindows) {
			
			if (StringTools.startsWith (path, "~/")) {
				
				path = Sys.getEnv ("HOME") + "/" + path.substr (2);
				
			}
			
		}
		
		return path;
		
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
					
					InstallTool.print("mkdir " + total);
					
					FileSystem.createDirectory (total);
					
				}
				
			}
			
		}
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
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
			
			FileSystem.deleteDirectory (directory);
			
		}
		
	}
	
	
	public static function tryFullPath (path:String):String {
		
		try {
			
			return FileSystem.fullPath (path);
			
		} catch (e:Dynamic) {
			
			return path;
			
		}
		
	}
		

}
