package helpers;


import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
import neko.Lib;


class FileHelper {
	
	
	public static function addFile (file:String):Bool {
		
		if (file != null && file != "") {
			
			//allFiles.push (file);
			InstallTool.print("Adding file to installer: " + file);
			
			return true;
			
		}
		
		return false;
		
	}
	
	
	public static function copyFile (source:String, destination:String, context:Dynamic, process:Bool = true) {
		
		var extension:String = Path.extension (source);
		
		if (process &&
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
			
			InstallTool.print("process " + source + " " + destination);
			
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
	
	
	public static function copyIfNewer (source:String, destination:String) {
      
		//allFiles.push (destination);
		
		if (!isNewer (source, destination)) {
			
			return;
			
		}
		
		InstallTool.print ("Copy " + source + " to " + destination);
		
		PathHelper.mkdir (Path.directory (destination));
		File.copy (source, destination);
		
	}
	
	
	public static function recursiveCopy (source:String, destination:String, context:Dynamic, process:Bool = true) {
		
		PathHelper.mkdir (destination);
		
		var files:Array <String> = null;
		
		try {
			
			files = FileSystem.readDirectory (source);
			
		} catch (e:Dynamic) {
			
			InstallTool.error ("Could not find source directory \"" + source + "\"");
			
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
	
	
	public static function isNewer (source:String, destination:String):Bool {
		
		if (source == null || !FileSystem.exists (source)) {
			
			InstallTool.error ("Source path \"" + source + "\" does not exist");
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
