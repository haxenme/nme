package installers;


import neko.io.Path;
import neko.Lib;
import neko.Sys;


class CPPInstaller extends InstallerBase {
	
	
	private var targetName:String;
	
	
	public function new (nme:String, command:String, defines:Hash <String>, includePaths:Array <String>, projectFile:String, target:String, verbose:Bool, debug:Bool) {
		
		super (nme, command, defines, includePaths, projectFile, target, verbose, debug);
		
		if (command != "rerun") {
			
			update ();
			
		}
		
		if (command == "build") {
			
			build ();
			
		}
		
		if (command == "build" || command == "rerun" || command == "update") {
			
			run ();
			
		}
		
	}
	
	
	private function build ():Void {
		
		var hxml:String = buildDirectory + "/" + targetName + "/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
		var destination:String = "";
		
		if (target == "mac") {
			
			destination = buildDirectory + "/" + targetName + "/" + defines.get ("APP_FILE") + ".app/Contents/MacOS";
			
		} else {
			
			destination = buildDirectory + "/" + targetName + "/" + defines.get ("APP_FILE");
			
		}
		
		var extension:String = "";
		
		if (target == "windows") {
			
			extension = ".exe";
			
		}
		
		if (debug) {
			
			copyIfNewer (buildDirectory + "/" + targetName + "/bin/ApplicationMain-debug" + extension, destination + "/ApplicationMain" + extension, verbose);
			
		} else {
			
			copyIfNewer (buildDirectory + "/" + targetName + "/bin/ApplicationMain" + extension, destination + "/ApplicationMain" + extension, verbose);
			
		}
		
		if (target != "windows") {
			
			runCommand ("", "chmod", [ "755", destination + "/ApplicationMain" + extension ]);
			
		}
		
	}
	
	
	private override function generateContext ():Void {
		
		var targetName:String = target;
		
		if (defines.exists ("NME_64")) {
			
			targetName += "64";
			
		}
		
		compilerFlags.push ("-D " + target);
		compilerFlags.push ("-cp " + buildDirectory + "/" + targetName + "/haxe");
		
		super.generateContext ();
		
	}
	
	
	private function run ():Void {
		
		var destination:String = "";
		
		if (target == "mac") {
			
			destination = buildDirectory + "/" + targetName + "/" + defines.get ("APP_FILE") + ".app/Contents/MacOS";
			
		} else {
			
			destination = buildDirectory + "/" + targetName + "/" + defines.get ("APP_FILE");
			
		}
		
		var dotSlash:String = "./";
		var extension:String = "";
		
		if (target == "windows") {
			
			dotSlash = ".\\";
			extension = ".exe";
			
		}
		
		runCommand (destination, dotSlash + "ApplicationMain" + extension, []);
		
	}
	
	
	private function update ():Void {
		
		var destination:String = "";
		
		if (target == "mac") {
			
			destination = buildDirectory + "/" + targetName + "/" + defines.get ("APP_FILE") + ".app/";
			
		} else {
			
			destination = buildDirectory + "/" + targetName + "/" + defines.get ("APP_FILE") + "/";
			
		}
		
		mkdir (destination);
		
		context.CPP_DIR = buildDirectory + "/" + targetName + "/bin";
		
		recursiveCopy (nme + "/install-tool/haxe", buildDirectory + "/" + targetName + "/haxe");
		recursiveCopy (nme + "/install-tool/cpp/hxml", buildDirectory + "/" + targetName + "/haxe");
		
		for (ndll in ndlls) {
			
			var extension:String = ".ndll";
			
			if (ndll.haxelib != "nme") {
				
				switch (target) {
					
					case "windows":
						
						extension = ".dll";
					
					case "linux":
						
						extension = ".dso";
					
					case "mac":
						
						extension = ".dylib";
					
				}
				
			}
			
			var directoryName:String = targetName.substr (0, 1).toUpperCase () + targetName.substr (1);
			copyIfNewer (ndll.getSourcePath (directoryName, ndll.name + extension), destination + ndll.name + extension, verbose);
			
		}
		
		var icon:String = defines.get ("APP_ICON");
		
		if (icon != null && icon != "") {
			
			copyIfNewer (icon, destination + "icon.png", verbose);
			
		}
		
		for (asset in assets) {
			
			mkdir (Path.directory (destination + asset.targetPath));
			copyIfNewer (asset.sourcePath, destination + asset.targetPath, verbose);
			
		}
		
	}
	
	
}
