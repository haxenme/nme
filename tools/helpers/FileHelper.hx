package;


import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
import neko.Lib;


class FileHelper {
	
	
	public static function copyFile (source:String, destination:String, context:Dynamic = null, process:Bool = true) {
		
		var extension:String = Path.extension (source);
		
		if (process && context != null && 
            (extension == "xml" ||
             extension == "java" ||
             extension == "hx" ||
             extension == "hxml" ||
			 extension == "html" || 
             extension == "ini" ||
             extension == "gpe" ||
             extension == "pch" ||
             extension == "pbxproj" ||
             extension == "plist" ||
             extension == "json" ||
             extension == "cpp" ||
             extension == "mm" ||
             extension == "properties")) {
			
			LogHelper.info ("", " - Copying template file: " + source + " -> " + destination);
			
			var fileContents:String = File.getContent (source);
			var template:Template = new Template (fileContents);
			var result:String = template.execute (context);
			var fileOutput:FileOutput = File.write (destination, true);
			fileOutput.writeString (result);
			fileOutput.close ();
			
		} else {
			
			copyIfNewer (source, destination);
			
		}
		
	}
	
	
	public static function copyFileTemplate (templatePaths:Array <String>, source:String, destination:String, context:Dynamic = null, process:Bool = true) {
		
		var path = PathHelper.findTemplate (templatePaths, source);
		
		if (path != null) {
			
			copyFile (path, destination, context, process);
			
		}
		
	}
	
	
	public static function copyIfNewer (source:String, destination:String) {
      
		//allFiles.push (destination);
		
		if (!isNewer (source, destination)) {
			
			return;
			
		}
		
		PathHelper.mkdir (Path.directory (destination));
		
		LogHelper.info ("", " - Copying file: " + source + " -> " + destination);
		File.copy (source, destination);
		
	}
	
	
	public static function copyLibrary (ndll:NDLL, directoryName:String, namePrefix:String, nameSuffix:String, targetDirectory:String, allowDebug:Bool = false) {
		
		var path = PathHelper.getLibraryPath (ndll, directoryName, namePrefix, nameSuffix, allowDebug);
		
		if (FileSystem.exists (path)) {
			
			var targetPath = targetDirectory + "/" + namePrefix + ndll.name + nameSuffix;
			
			PathHelper.mkdir (targetDirectory);
			LogHelper.info ("", " - Copying library file: " + path + " -> " + targetPath);
			File.copy (path, targetPath);
			
		} else {
			
			LogHelper.error ("Source path \"" + path + "\" does not exist");
			
		}
		
	}
	
	
	public static function recursiveCopy (source:String, destination:String, context:Dynamic = null, process:Bool = true) {
		
		PathHelper.mkdir (destination);
		
		var files:Array <String> = null;
		
		try {
			
			files = FileSystem.readDirectory (source);
			
		} catch (e:Dynamic) {
			
			LogHelper.error ("Could not find source directory \"" + source + "\"");
			
		}
		
		for (file in files) {
			
			if (file.substr (0, 1) != ".") {
				
				var itemDestination:String = destination + "/" + file;
				var itemSource:String = source + "/" + file;
				
				if (FileSystem.isDirectory (itemSource)) {
					
					recursiveCopy (itemSource, itemDestination, context, process);
					
				} else {
					
					copyFile (itemSource, itemDestination, context, process);
					
				}
				
			}
			
		}
		
	}
	
	
	public static function recursiveCopyTemplate (templatePaths:Array <String>, source:String, destination:String, context:Dynamic = null, process:Bool = true) {
		
		var paths = PathHelper.findTemplates (templatePaths, source);
		
		for (path in paths) {
			
			recursiveCopy (path, destination, context, process);
			
		}
		
	}
	
	
	public static function isNewer (source:String, destination:String):Bool {
		
		if (source == null || !FileSystem.exists (source)) {
			
			LogHelper.error ("Source path \"" + source + "\" does not exist");
			return false;
			
		}
		
		if (FileSystem.exists (destination)) {
			
			if (FileSystem.stat (source).mtime.getTime () < FileSystem.stat (destination).mtime.getTime ()) {
				
				return false;
				
			}
			
		}
		
		return true;
		
	}
		

}
