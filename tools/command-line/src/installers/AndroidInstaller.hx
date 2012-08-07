package installers;


import data.Asset;
import haxe.io.Path;
import helpers.AndroidHelper;
import helpers.FileHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import helpers.SWFHelper;
import sys.io.File;
import sys.FileSystem;


class AndroidInstaller extends InstallerBase {
	
	
	override function build ():Void {
		
		var destination:String = buildDirectory + "/android/bin";
		var hxml:String = buildDirectory + "/android/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		var arm5 = buildDirectory + "/android/bin/libs/armeabi/libApplicationMain.so";
		var arm7 = buildDirectory + "/android/bin/libs/armeabi-v7a/libApplicationMain.so";
		
		if (!defines.exists ("ARM7-only")) {
			
			ProcessHelper.runCommand ("", "haxe", [ hxml ] );
			FileHelper.copyIfNewer (buildDirectory + "/android/obj/libApplicationMain" + (debug ? "-debug" : "") + ".so", arm5);
			
		} else {
			
			if (FileSystem.exists (arm5)) {
				
				FileSystem.deleteFile (arm5);
				
			}
			
		}
		
		if (defines.exists ("ARM7") || defines.exists ("ARM7-only")) {
			
			ProcessHelper.runCommand ("", "haxe", [ hxml, "-D", "HXCPP_ARM7" ] );
			FileHelper.copyIfNewer (buildDirectory + "/android/obj/libApplicationMain-7" + (debug ? "-debug" : "") + ".so", arm7);
			
		} else {
			
			if (FileSystem.exists (arm7)) {
				
				FileSystem.deleteFile (arm7);
				
			}
			
		}
		
		AndroidHelper.build (destination);
		
	}
	
	
	override function clean ():Void {
		
		var targetPath = buildDirectory + "/android";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	override function generateContext ():Void {
		
		AndroidHelper.initialize (defines);
		
		super.generateContext ();
		
		context.CPP_DIR = buildDirectory + "/android/obj";
		
		if (defines.exists ("KEY_STORE")) {
			
			context.KEY_STORE = PathHelper.tryFullPath (defines.get ("KEY_STORE"));
			
		}
		
		updateIcon();
		
	}
	
	
	override function onCreate ():Void {
		
		if (!defines.exists ("ANDROID_SETUP")) {
			
			throw "You need to run \"nme setup android\" before you can use the Android target";
			
		}
		
	}
	
	
	override function run ():Void {
		
		AndroidHelper.run (defines.get ("APP_PACKAGE") + "/" + defines.get ("APP_PACKAGE") + ".MainActivity");
		
	}
	
	
	override function traceMessages ():Void {
		
		AndroidHelper.trace (debug);
		
	}
	
	
	override function uninstall ():Void {
		
		AndroidHelper.uninstall (defines.get ("APP_PACKAGE"));
		
	}
	

	private function updateIcon () {
		
		var destination:String = buildDirectory + "/android/bin";
		PathHelper.mkdir (destination);
		PathHelper.mkdir (destination + "/res/drawable-ldpi/");
		PathHelper.mkdir (destination + "/res/drawable-mdpi/");
		PathHelper.mkdir (destination + "/res/drawable-hdpi/");
		
		var orig = allFiles.length;
		
		if (icons.updateIcon (36, 36, destination + "/res/drawable-ldpi/icon.png"))
			allFiles.push(destination + "/res/drawable-ldpi/icon.png");
		if (icons.updateIcon (48, 48, destination + "/res/drawable-mdpi/icon.png"))
			allFiles.push(destination + "/res/drawable-mdpi/icon.png");
		if (icons.updateIcon (72, 72, destination + "/res/drawable-hdpi/icon.png"))
			allFiles.push(destination + "/res/drawable-hdpi/icon.png");
		if (icons.updateIcon (96, 96, destination + "/res/drawable-xhdpi/icon.png"))
			allFiles.push(destination + "/res/drawable-xhdpi/icon.png");
		
		if (orig != allFiles.length)
			context.HAS_ICON = true;
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/android/bin/";
		PathHelper.mkdir (destination);
		
		var packageDirectory:String = defines.get ("APP_PACKAGE");
		packageDirectory = destination + "/src/" + packageDirectory.split (".").join ("/");
		PathHelper.mkdir (packageDirectory);
		
		SWFHelper.generateSWFClasses (NME, swfLibraries, buildDirectory + "/android/haxe");
		
		for (ndll in ndlls) {
			
			var ndllPath = ndll.getSourcePath ("Android", "lib" + ndll.name + "-debug.so");
			var debugExists = FileSystem.exists (ndllPath);
			
			if (!debug || !debugExists) {
				
				ndllPath = ndll.getSourcePath ("Android", "lib" + ndll.name + ".so");
				
			}
			
			if (debugExists) {
				
				PathHelper.mkdir (destination + "/libs/armeabi/");
				File.copy (ndllPath, destination + "/libs/armeabi/lib" + ndll.name + ".so");
				
			} else {
				
				FileHelper.copyIfNewer (ndllPath, destination + "/libs/armeabi/lib" + ndll.name + ".so");
				
			}
			
		}
		
		for (javaPath in javaPaths) {
			
			//try {
				
				if (FileSystem.isDirectory (javaPath)) {
					
					FileHelper.recursiveCopy (javaPath, destination + "/src", context, true);
					
				} else {
					
					FileHelper.copyIfNewer (javaPath, destination + "/src/" + Path.withoutDirectory (javaPath));
					
				}
				
			//} catch (e:Dynamic) {
				
			//	throw"Could not find javaPath " + javaPath +" required by extension."; 
				
			//}
			
		}
		
		for (asset in assets) {
			
			if (asset.type != Asset.TYPE_TEMPLATE) {
				
				var targetPath:String = "";
				
				switch (asset.type) {
					
					case Asset.TYPE_SOUND, Asset.TYPE_MUSIC:
						
						asset.resourceName = asset.id;
						targetPath = destination + "/res/raw/" + asset.flatName + "." + Path.extension (asset.targetPath);
					
					default:
						
						asset.resourceName = asset.flatName;
						targetPath = destination + "/assets/" + asset.resourceName;
					
				}
				
				FileHelper.copyIfNewer (asset.sourcePath, targetPath);
				
			}
			
		}
		
		FileHelper.recursiveCopy (templatePaths[0] + "android/template", destination, context);
		FileHelper.copyFile (templatePaths[0] + "android/MainActivity.java", packageDirectory + "/MainActivity.java", context);
		FileHelper.recursiveCopy (templatePaths[0] + "haxe", buildDirectory + "/android/haxe", context);
		FileHelper.recursiveCopy (templatePaths[0] + "android/hxml", buildDirectory + "/android/haxe", context);
		
		for (asset in assets) {
			
			if (asset.type == Asset.TYPE_TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (destination + asset.targetPath));
				FileHelper.copyFile (asset.sourcePath, destination + asset.targetPath, context);
				
			}
			
		}
		
	}
	
	
	override function updateDevice ():Void {
		
		var build:String = "debug";
		
		if (defines.exists ("KEY_STORE")) {
			
			build = "release";
			
		}
		
		AndroidHelper.install (FileSystem.fullPath (buildDirectory) + "/android/bin/bin/" + defines.get ("APP_FILE") + "-" + build + ".apk");
		
   }
	
	
}
