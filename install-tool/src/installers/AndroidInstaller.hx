package installers;


import data.Asset;
import neko.io.Path;
import neko.FileSystem;
import neko.Lib;
import neko.Sys;


class AndroidInstaller extends InstallerBase {
	
	
	override function build ():Void {
		
		var destination:String = buildDirectory + "/android/bin";
		mkdir (destination);
		
		context.CPP_DIR = buildDirectory + "/android/obj";
		
		recursiveCopy (NME + "/install-tool/android/template", destination);
		
		var packageDirectory:String = defines.get ("APP_PACKAGE");
		packageDirectory = destination + "/src/" + packageDirectory.split (".").join ("/");
		mkdir (packageDirectory);
		
		copyFile (NME + "/install-tool/android/MainActivity.java", packageDirectory + "/MainActivity.java");
		recursiveCopy (NME + "/install-tool/haxe", buildDirectory + "/android/haxe");
		recursiveCopy (NME + "/install-tool/android/hxml", buildDirectory + "/android/haxe");
		
		var hxml:String = buildDirectory + "/android/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
		copyIfNewer (buildDirectory + "/android/obj/libApplicationMain" + (debug ? "-debug" : "") + ".so", buildDirectory + "/android/bin/libs/armeabi/libApplicationMain.so");
		
		if (defines.exists ("JAVA_HOME")) {
			
			Sys.putEnv ("JAVA_HOME", defines.get ("JAVA_HOME"));
			
		}
		
		if (defines.exists ("ANDROID_SDK")) {
			
			Sys.putEnv ("ANDROID_SDK", defines.get ("ANDROID_SDK"));
			
		}
		
		var ant:String = defines.get ("ANT_HOME");
		
		if (ant == null || ant == "") {
			
			ant = "ant";
			
		} else {
			
			ant += "/bin/ant";
			
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
		
		if (!InstallTool.isWindows) {
			
			name = "./" + name;
			
		}
		
		return { path: path, name: name };
		
	}

	override function generateContext ():Void {
		super.generateContext ();
      updateIcon();
	}
	
	
	override function onCreate ():Void {
		
		if (!defines.exists ("ANDROID_SETUP")) {
			
			throw "You need to run \"nme setup android\" before you can use the Android target";
			
		}
		
		if (Sys.getEnv ("ANDROID_HOST") != null && Sys.getEnv ("ANDROID_HOST") != "") {
			
			if (InstallTool.isLinux) {
				
				Sys.putEnv ("ANDROID_HOST", "linux-x86");
				
			} else {
				
				Sys.putEnv ("ANDROID_HOST", "windows");
				
			}
			
		}
		
	}
	
	
	override function run ():Void {
		
		var pack:String = defines.get ("APP_PACKAGE");
		var adb:Dynamic = getADB ();
		
		runCommand (adb.path, adb.name, [ "shell", "am start -a android.intent.action.MAIN -n " + pack + "/" + pack + ".MainActivity" ]);
		
	}
	
	
	override function traceMessages ():Void {
		
		var adb:Dynamic = getADB ();
		runCommand (adb.path, adb.name, [ "logcat", "*:D" ]);
		
	}
	
	
	override function uninstall ():Void {
		
		var adb:Dynamic = getADB ();
		var pack:String = defines.get ("APP_PACKAGE");
		
		runCommand (adb.path, adb.name, [ "uninstall", pack ]);
		
	}

   function updateIcon()
   {
		var destination:String = buildDirectory + "/android/bin";
		mkdir (destination);
		mkdir (destination + "/res/drawable-ldpi/");
		mkdir (destination + "/res/drawable-mdpi/");
		mkdir (destination + "/res/drawable-hdpi/");
		
      var orig = allFiles.length;

		if (icons.updateIcon (36, 36, destination + "/res/drawable-ldpi/icon.png") )
         allFiles.push(destination + "/res/drawable-ldpi/icon.png");
		if (icons.updateIcon (48, 48, destination + "/res/drawable-mdpi/icon.png") )
         allFiles.push(destination + "/res/drawable-mdpi/icon.png");
		if (icons.updateIcon (72, 72, destination + "/res/drawable-hdpi/icon.png") )
         allFiles.push(destination + "/res/drawable-hdpi/icon.png");

      if (orig!=allFiles.length)
         context.HAS_ICON = true;
   }
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/android/bin";

		for (ndll in ndlls) {
			
			copyIfNewer (ndll.getSourcePath ("Android", "lib" + ndll.name + ".so"), destination + "/libs/armeabi/lib" + ndll.name + ".so" );
			
		}
		
		for (asset in assets) {
			
			var targetPath:String = "";
			
			switch (asset.type) {
				
				case Asset.TYPE_SOUND, Asset.TYPE_MUSIC:

					targetPath = destination + "/res/raw/" + asset.flatName + "." + Path.extension (asset.targetPath);
				default:
					
			      asset.resourceName = asset.flatName;
					targetPath = destination + "/assets/" + asset.resourceName;
				
			}
			
			copyIfNewer (asset.sourcePath, targetPath );
			
		}
		
	}
	
	
	override function updateDevice ():Void {
		
		var build:String = "debug";
		
		if (defines.exists ("KEY_STORE")) {
			
			build = "release";
			
		}
		
		var apk:String = FileSystem.fullPath (buildDirectory) + "/android/bin/bin/" + defines.get ("APP_FILE") + "-" + build + ".apk";
		var adb:Dynamic = getADB ();
		
		runCommand (adb.path, adb.name, [ "install", "-r", apk ]);
		
   }
	
	
}
