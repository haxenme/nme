package installers;


import data.Asset;
import neko.FileSystem;
import neko.io.Path;


/**
 * ...
 * @author Joshua Granick
 */

class HTML5Installer extends InstallerBase {
	
	
	override function build ():Void {
		
		var hxml:String = buildDirectory + "/html5/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
	}
	
	
	override function clean ():Void {
		
		var targetPath = buildDirectory + "/html5/";
		
		if (FileSystem.exists (targetPath)) {
			
			removeDirectory (targetPath);
			
		}
		
	}
	
	
	private function generateFontData (font:Asset, destination:String):Void {
		
		var sourcePath = font.sourcePath;
		var targetPath = destination + font.targetPath;
		
		if (!FileSystem.exists (FileSystem.fullPath (sourcePath) + ".hash")) {
			
			runCommand (Path.directory (targetPath), "neko", [ NME + "/tools/command-line/html5/hxswfml.n", "ttf2hash", FileSystem.fullPath (sourcePath), "-glyphs", "32-255" ] );
			
		}
		
		context.HAXE_FLAGS += "\n-resource " + FileSystem.fullPath (sourcePath) + ".hash@NME_" + font.flatName;
		
	}
	
	
	override function run ():Void {
		
		var destination:String = buildDirectory + "/html5/bin";
		var dotSlash:String = "./";
		
		if (InstallTool.isWindows) {
			
			runCommand (destination, ".\\index.html", []);
			
		} else if (InstallTool.isMac) {
			
			runCommand (destination, "open", [ "index.html" ]);
			
		} else {
			
			runCommand (destination, "xdg-open", [ "index.html" ]);
			
		}
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/html5/bin/";
		mkdir (destination);
		
		for (asset in assets) {
			
			if (asset.type != Asset.TYPE_TEMPLATE) {
				
				mkdir (Path.directory (destination + asset.targetPath));
				
				if (asset.type != Asset.TYPE_FONT) {
					
					// going to root directory now, but should it be a forced "assets" folder later?
					
					copyIfNewer (asset.sourcePath, destination + asset.targetPath);
					
				} else {
					
					generateFontData (asset, destination);
					
				}
				
			}
			
		}
		
		recursiveCopy (NME + "/tools/command-line/html5/template", destination);
		recursiveCopy (NME + "/tools/command-line/haxe", buildDirectory + "/html5/haxe");
		recursiveCopy (NME + "/tools/command-line/html5/haxe", buildDirectory + "/html5/haxe");
		recursiveCopy (NME + "/tools/command-line/html5/hxml", buildDirectory + "/html5/haxe");
		
		for (asset in assets) {
						
			if (asset.type == Asset.TYPE_TEMPLATE) {
				
				mkdir (Path.directory (destination + asset.targetPath));
				copyFile (asset.sourcePath, destination + asset.targetPath);
				
			}
			
		}
		
	}
	
	
}