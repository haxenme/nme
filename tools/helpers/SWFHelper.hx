package;


import format.SWF;
import haxe.io.Path;
import haxe.Template;
import nme.utils.ByteArray;
import sys.io.File;
import sys.FileSystem;


class SWFHelper {
	
	
	public static function generateSWFClasses (project:NMEProject, outputDirectory:String):Void {
		
		return null;
		
		/*var movieClipTemplate = File.getContent (PathHelper.findTemplate (project.templatePaths, "resources/swf/MovieClip.mtt"));
		var simpleButtonTemplate = File.getContent (PathHelper.findTemplate (project.templatePaths, "resources/swf/SimpleButton.mtt"));
		
		for (asset in project.libraries) {
			
			if (!FileSystem.exists (asset.sourcePath)) {
				
				LogHelper.error ("SWF library path \"" + asset.sourcePath + "\" does not exist");
				
			}
			
			var input = File.read (asset.sourcePath, true);
			var data = new ByteArray ();
			
			try {
				
				while (true) {
					
					data.writeByte (input.readByte ());
					
				}
				
			} catch (e:Dynamic) {
				
			}
			
			data.position = 0;
			
			var swf = new SWF (data);
			
			for (className in swf.symbols.keys ()) {
				
				var lastIndexOfPeriod = className.lastIndexOf (".");
				var packageName = "";
				var name = "";
				
				if (lastIndexOfPeriod == -1) {
					
					name = className;
					
				} else {
					
					packageName = className.substr (0, lastIndexOfPeriod);
					name = className.substr (lastIndexOfPeriod + 1);
					
				}
				
				packageName = packageName.toLowerCase ();
				name = name.substr (0, 1).toUpperCase () + name.substr (1);
				
				var symbolID = swf.symbols.get (className);
				var templateData = null;
				
				switch (swf.getSymbol (symbolID)) {
					
					case spriteSymbol (data):
						
						templateData = movieClipTemplate;
					
					case buttonSymbol (data):
						
						templateData = simpleButtonTemplate;
					
					default:
					
				}
				
				if (templateData != null) {
					
					var context = { PACKAGE_NAME: packageName, CLASS_NAME: name, SWF_ID: asset.id, SYMBOL_ID: symbolID };
					var template = new Template (templateData);
					var result = template.execute (context);
					
					var directory = outputDirectory + "/" + Path.directory (className.split (".").join ("/"));
					var fileName = name + ".hx";
					
					PathHelper.mkdir (directory);
					
					var path = PathHelper.combine (directory, fileName);
					LogHelper.info ("", " - Generating SWF class: " + path);
					
					var fileOutput = File.write (path, true);
					fileOutput.writeString (result);
					fileOutput.close ();
					
				}
				
			}
			
		}*/
		
	}
	
	
	public static function preprocess (project:NMEProject):Void {
		
		for (library in project.libraries) {
			
			if (library.type == LibraryType.SWF) {
				
				project.haxelibs.remove ("swf");
				project.haxelibs.push ("swf");
				
				project.assets.push (new Asset (library.sourcePath, "libraries/" + library.name + ".swf", AssetType.BINARY));
				
			}
			
		}
		
	}
	

}
