package helpers;


import data.Asset;
import format.SWF;
import haxe.io.Path;
import haxe.Template;
import nme.utils.ByteArray;
import sys.io.File;
import sys.FileSystem;


class SWFHelper {
	
	
	public static function generateSWFClasses (NME:String, swfLibraries:Array <Asset>, outputDirectory:String):Void {
		
		var movieClipTemplate = File.getContent (NME + "/tools/command-line/resources/swf/MovieClip.mtt");
		var simpleButtonTemplate = File.getContent (NME + "/tools/command-line/resources/swf/SimpleButton.mtt");
		
		for (asset in swfLibraries) {
			
			if (!FileSystem.exists (asset.sourcePath)) {
				
				InstallTool.error ("SWF library path \"" + asset.sourcePath + "\" does not exist");
				
			}
			
			var input = File.read (asset.sourcePath, true);
			var data = new ByteArray ();
			
			try {
				
				while (true) {
					
					data.writeByte (input.readByte ());
					
				}
				
			} catch (e:Dynamic) {
				
			}
			
			var swf = new SWF (data);
			
			for (className in swf.symbols.keys ()) {
				
				var lastIndexOfPeriod:Int = className.lastIndexOf (".");
				
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
					
					var fileOutput = File.write (directory + "/" + fileName, true);
					fileOutput.writeString (result);
					fileOutput.close ();
					
				}
				
			}
			
		}
		
	}
		

}
