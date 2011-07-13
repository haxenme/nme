package installers;


import data.Asset;
import neko.io.Path;
import neko.FileSystem;
import neko.Lib;


class AndroidInstaller extends InstallerBase {
	
	
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
		
		if (command == "uninstall") {
			
			uninstall ();
			
		}
		
	}
	
	
	private function build ():Void {
		
		var hxml:String = buildDirectory + "/android/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
		var ant:String = defines.get ("ANT_HOME");
		
		if (ant == null || ant == "") {
			
			ant = "ant";
			
		} else {
			
			ant += "/bin/ant";
			
		}
		
		var destination:String = buildDirectory + "/android/project";
		
		for (asset in assets) {
			
			asset.resourceName = generateFlatName (asset.id);
			var targetPath:String = "";
			
			switch (asset.type) {
				
				case Asset.TYPE_SOUND:
					
					targetPath = destination + "/res/raw/" + asset.resourceName + "." + Path.extension (asset.targetPath);
				
				case Asset.TYPE_MUSIC:
					
					targetPath = destination + "/res/raw/" + asset.resourceName + "." + Path.extension (asset.targetPath);
				
				default:
					
					targetPath = destination + "/assets/" + asset.id;
				
			}
			
			mkdir (Path.directory (targetPath));
			copyIfNewer (asset.sourcePath, targetPath, verbose);
			
		}
		
		var build:String = "debug";
		
		if (defines.exists ("KEY_STORE")) {
			
			build = "release";
			
		}
		
		runCommand (destination, ant, [ build ]);
		
	}
	
	
	private function getADB ():Dynamic {
		
		var path:String = defines.get ("ANDROID_SDK") + "/tools/";
		var name:String = "adb";
		
		if (defines.get ("HOST") == "windows") {
			
			name += ".exe";
			
		}
		
		if (!FileSystem.exists (path + name)) {
			
			path = defines.get ("ANDROID_SDK") + "/platform-tools/";
			
		}
		
		return { path: path, name: name };
		
	}
	
	
	private function getFlatName (id:String, flatNames:Hash <String>):String {
		
		var chars:String = id.toLowerCase ();
		var flatName:String = "";
		
		for (i in 0...chars.length) {
			
			var code = chars.charCodeAt (i);
			
			if ((i > 0 && code >= "0".charCodeAt (0) && code <= "9".charCodeAt (0)) || (code >= "a".charCodeAt (0) && code <= "z".charCodeAt (0)) || (code == "_".charCodeAt (0))) {
				
				flatName += chars.charAt (i);
				
			} else {
				
				flatName += "_";
				
			}
			
		}
		
		if (flatName == "") {
			
			flatName = "_";
			
		}
		
		while (flatNames.exists (flatName)) {
			
			flatName += "_";
		 
		}
		
		flatNames.set (flatName, "1");
		
		return flatName;
		
	}
	
	
	private function run ():Void {
		
		var build:String = "debug";
		
		if (defines.exists ("KEY_STORE")) {
			
			build = "release";
			
		}
		
		var apk:String = FileSystem.fullPath (buildDirectory) + "/android/project/bin/" + defines.get ("APP_FILE") + "-" + build + ".apk";
		var adb:Dynamic = getADB ();
		
		runCommand (adb.path, adb.name, [ "install", "-r", apk ]);
		
		var pack:String = defines.get ("APP_PACKAGE");
		
		runCommand (adb.path, adb.name, [ "shell", "am start -a android.intent.action.MAIN -n " + pack + "/" + pack + ".MainActivity" ]);
		runCommand (adb.path, adb.name, [ "logcat", "*:D" ]);
		
	}
	
	
	private function uninstall ():Void {
		
		var adb:Dynamic = getADB ();
		var pack:String = defines.get ("APP_PACKAGE");
		
		runCommand (adb.path, adb.name, [ "uninstall", pack ]);
		
	}
	
	
	private function update ():Void {
		
		var destination:String = buildDirectory + "/android/project";
		mkdir (destination);
		
		//createIcon (36, 36, destination + "/res/drawable-ldpi/icon.png", true);
		//createIcon (48, 48, destination + "/res/drawable-mdpi/icon.png", true);
		//createIcon (72, 72, destination + "/res/drawable-hdpi/icon.png", true);
		
		recursiveCopy (nme + "/install-tool/android/template", destination);
		
		var packageDirectory:String = defines.get ("APP_PACKAGE");
		packageDirectory = destination + "/src/" + packageDirectory.split (".").join ("/");
		mkdir (packageDirectory);
		
		copyFile (nme + "/install-tool/android/MainActivity.java", packageDirectory + "/MainActivity.java");
		recursiveCopy (nme + "/install-tool/haxe", buildDirectory + "/android/haxe");
		recursiveCopy (nme + "/install-tool/android/hxml", buildDirectory + "/android/haxe");
		
		for (ndll in ndlls) {
			
			copyIfNewer (ndll.getSourcePath ("Android", "lib" + ndll.name + ".so"), destination + "/libs/armeabi/lib" + ndll.name + ".so", verbose);
			
		}
		
	}
	
	
}
