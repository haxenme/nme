package installers;


import neko.FileSystem;
import neko.io.Path;
import neko.Lib;


class IOSInstaller extends InstallerBase {
	
	
	public function new (nme:String, command:String, defines:Hash <String>, includePaths:Array <String>, projectFile:String, target:String, verbose:Bool, debug:Bool) {
		
		super (nme, command, defines, includePaths, projectFile, target, verbose, debug);
		
		if (command == "build" || command == "rerun") {
			
			throw ("You must use the \"update\" command to build or run the iOS target");
			
		}
		
		if (command != "rerun") {
			
			update ();
			
		}
		
	}
	
	
	private override function generateContext ():Void {
		
		for (i in 0...compilerFlags.length) {
			
			if (compilerFlags[i].substr (0, 4) == "-cp ") {
				
				compilerFlags[i] = "-cp " + FileSystem.fullPath (compilerFlags[i].substr (4));
				
			}
			
		}
		
		super.generateContext ();
		
	}
	
	
	private function update ():Void {
		
		var destination:String = buildDirectory + "/iphone/";
		mkdir (destination);
		
		/*var has_icon = true;
      for(i in 0...4)
      {
         var iname = ["Icon.png", "Icon@2x.png", "Icon-72.png", "Icon-Small.png" ][i];
         var size = [57,114,72,50][i];
         var bmp = getIconBitmap(size,size,"",{a:255,rgb:0} );
         if (bmp!=null)
         {
            var name = dest + "/" + iname;
            var bytes = bmp.encode("PNG",0.95);
            bytes.writeFile(name);
            mAllFiles.push(name);
         }
         else
            has_icon = false;
      }*/
		
		context.HAS_ICON = false;
		
		recursiveCopy (nme + "/install-tool/iphone/haxe", destination + "/haxe");
		recursiveCopy (nme + "/install-tool/iphone/Classes", destination + "Classes");
		recursiveCopy (nme + "/install-tool/iphone/PROJ.xcodeproj", destination + defines.get ("APP_FILE") + ".xcodeproj");
		copyFile (nme + "/install-tool/iphone/PROJ-Info.plist", destination + defines.get ("APP_FILE") + "-Info.plist");
		
		mkdir (destination + "lib");
		
		for (ndll in ndlls) {
			
			if (ndll.name != "nme") {
				
				copyIfNewer (ndll.getSourcePath ("iPhone", "lib" + ndll.name + "." + target + ".a"), destination + "lib/" + ndll.name + "." + target + ".a", verbose);
				
			} else {
				
				copyIfNewer (ndll.getSourcePath ("iPhone", "nme." + target + ".a"), destination + "lib/nme." + target + ".a", verbose);
				
			}
			
		}
		
		for (asset in assets) {
			
			mkdir (Path.directory (destination + asset.targetPath));
			copyIfNewer (asset.sourcePath, destination + "assets/" + asset.id, verbose);
			
		}
		
	}
	
	
}
