package installers;


import data.Asset;
import data.NDLL;
import haxe.io.Path;
import neko.Lib;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;


class BlackBerryInstaller extends InstallerBase {

	
	private var binDirectory:String;
   
	
	override function build ():Void {
		
		var hxml:String = buildDirectory + "/blackberry/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
		if (debug) {
			
			copyIfNewer (buildDirectory + "/blackberry/obj/ApplicationMain-debug", buildDirectory + "/blackberry/bin/" + defines.get ("APP_FILE"));
			
		} else {
			
			copyIfNewer (buildDirectory + "/blackberry/obj/ApplicationMain", buildDirectory + "/blackberry/bin/" + defines.get ("APP_FILE"));
			
		}
		
		var args = [ "-package", defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + ".bar", "bin/bar-descriptor.xml" ];
		
		if (defines.exists ("KEY_STORE")) {
			
			args.push ("-keystore");
			args.push (tryFullPath (defines.get ("KEY_STORE")));
			
			if (defines.exists ("KEY_STORE_PASSWORD")) {
				
				args.push ("-storepass");
				args.push (defines.get ("KEY_STORE_PASSWORD"));
				
			}
			
		} else {
			
			args.push ("-devMode");
			
			if (!targetFlags.exists ("simulator")) {
				
				args.push ("-debugToken");
				args.push (tryFullPath (defines.get ("BLACKBERRY_DEBUG_TOKEN")));
				
			}
			
		}
		
		runCommand (buildDirectory + "/blackberry", binDirectory + "blackberry-nativepackager", args);
		
		if (defines.exists ("KEY_STORE")) {
			
			args = [ "-keystore", tryFullPath (defines.get ("KEY_STORE")) ];
			
			if (defines.exists ("KEY_STORE_PASSWORD")) {
				
				args.push ("-storepass");
				args.push (defines.get ("KEY_STORE_PASSWORD"));
				
			}
			
			args.push (defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + ".bar");
			
			runCommand (buildDirectory + "/blackberry", binDirectory + "blackberry-signer", args);
			
		}
		
	}
	
	
	override function clean ():Void {
		
		var targetPath = buildDirectory + "/blackberry";
		
		if (FileSystem.exists (targetPath)) {
			
			removeDirectory (targetPath);
			
		}
		
	}
	
	
	override function generateContext ():Void {
		
		if (InstallTool.isWindows) {
			
			binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/win32/x86/usr/bin/";
			
		} else if (InstallTool.isMac) {
			
			binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/macosx/x86/usr/bin/";
			
		} else {
			
			binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/linux/x86/usr/bin/";
			
		}
		
		for (asset in assets) {
			
			asset.resourceName = "app/native/" + asset.resourceName;
			
		}
		
		if (targetFlags.exists ("simulator")) {
			
			compilerFlags.push ("-D simulator");
			
		}
		
		super.generateContext ();
		
		context.CPP_DIR = buildDirectory + "/blackberry/obj";
		context.BLACKBERRY_AUTHOR_ID = getAuthorID ();
		
		updateIcon ();
		
	}
	
	
	private function getAuthorID ():String {
		
		if (defines.exists ("BLACKBERRY_DEBUG_TOKEN")) {
			
			InstallTool.mkdir (buildDirectory + "/blackberry");
			
			var cacheCwd = Sys.getCwd ();
			Sys.setCwd (buildDirectory + "/blackberry");
			
			var process = new Process(binDirectory + "blackberry-nativepackager", [ "-listmanifest", escapePath (tryFullPath (defines.get ("BLACKBERRY_DEBUG_TOKEN"))) ]);
			var ret = process.stdout.readAll().toString();
			var ret2 = process.stderr.readAll().toString();
			process.exitCode(); //you need this to wait till the process is closed!
			process.close();
			
			Sys.setCwd (cacheCwd);
			
			if (ret != null) {
				
				var search = "Package-Author-Id: ";
				var index = ret.indexOf (search);
				
				if (index > -1) {
					
					var start = index + search.length;
					return ret.substr (start, ret.indexOf ("\n", index) - start);
					
				}
				
			}
			
		}
		
		if (targetFlags.exists ("simulator")) {
			
			return "gYAAgF-DMYiFsOQ3U6QvuW1fQDY";
			
		} else {
			
			return "";
			
		}
		
	}
	
	
	override function onCreate ():Void {
		
		if (!defines.exists ("BLACKBERRY_SETUP")) {
			
			throw "You need to run \"nme setup blackberry\" before you can use the BlackBerry target";
			
		}
		
	}
	
	
	override function run ():Void {
		
		var deviceIP = defines.get ("BLACKBERRY_DEVICE_IP");
		var devicePassword = defines.get ("BLACKBERRY_DEVICE_PASSWORD");
		
		if (targetFlags.exists ("simulator")) {
			
			deviceIP = defines.get ("BLACKBERRY_SIMULATOR_IP");
			devicePassword = "playbook";
			
		}
		
		runCommand (buildDirectory + "/blackberry", binDirectory + "blackberry-deploy", [ "-installApp", "-launchApp", "-device", deviceIP, "-password", devicePassword, defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + ".bar" ] );
		
	}
	
	
	override function traceMessages ():Void {
		
		var deviceIP = defines.get ("BLACKBERRY_DEVICE_IP");
		var devicePassword = defines.get ("BLACKBERRY_DEVICE_PASSWORD");
		
		if (targetFlags.exists ("simulator")) {
			
			deviceIP = defines.get ("BLACKBERRY_SIMULATOR_IP");
			devicePassword = "playbook";
			
		}
		
		runCommand (buildDirectory + "/blackberry", binDirectory + "blackberry-deploy", [ "-getFile", "logs/log", "-", "-device", deviceIP, "-password", devicePassword, defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + ".bar" ] );
		
		//runPalmCommand (false, "log", [ "-f", defines.get ("APP_PACKAGE") ]);
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/blackberry/bin/";
		mkdir (destination);
		
		recursiveCopy (templatePaths[0] + "blackberry/template", destination);
		recursiveCopy (templatePaths[0] + "haxe", buildDirectory + "/blackberry/haxe");
		recursiveCopy (templatePaths[0] + "blackberry/hxml", buildDirectory + "/blackberry/haxe");
		generateSWFClasses (buildDirectory + "/blackberry/haxe");
		
		var arch = "";
		
		if (targetFlags.exists ("simulator")) {
			
			arch = "-x86";
			
		}
		
		ndlls.push (new NDLL ("libTouchControlOverlay", "nme"));
		
		for (ndll in ndlls) {
			
			var ndllPath = ndll.getSourcePath ("BlackBerry", ndll.name + "-debug" + arch + ".so");
			var debugExists = FileSystem.exists (ndllPath);
			
			if (!debug || !debugExists) {
				
				ndllPath = ndll.getSourcePath ("BlackBerry", ndll.name + arch + ".so");
				
			}
			
			File.copy (ndllPath, destination + ndll.name + ".so");
			
		}
		
		var linkedLibraries = [ new NDLL ("libSDL", "nme") ];
		
		for (ndll in linkedLibraries) {
			
			var deviceLib = ndll.name + ".so";
			var simulatorLib = ndll.name + "-x86.so";
			
			if (targetFlags.exists ("simulator")) {
				
				if (FileSystem.exists (destination + deviceLib)) {
					
					FileSystem.deleteFile (destination + deviceLib);
					
				}
				
				copyIfNewer (ndll.getSourcePath ("BlackBerry", simulatorLib), destination + simulatorLib);
				
			} else {
				
				if (FileSystem.exists (destination + simulatorLib)) {
					
					FileSystem.deleteFile (destination + simulatorLib);
					
				}
				
				copyIfNewer (ndll.getSourcePath ("BlackBerry", deviceLib), destination + deviceLib);
				
			}
			
		}
		
		for (asset in assets) {
			
			mkdir (Path.directory (destination + asset.targetPath));
			
			if (asset.type != Asset.TYPE_TEMPLATE) {
				
				// going to root directory now, but should it be a forced "assets" folder later?
				
				copyIfNewer (asset.sourcePath, destination + asset.targetPath);
				
			} else {
				
				copyFile (asset.sourcePath, destination + asset.targetPath);
				
			}
			
		}
		
	}
	
	
	private function updateIcon ():Void {
		
		var icon_name = icons.findIcon (86, 86);
		
		if (icon_name == "") {
			
			var tmpDir = buildDirectory + "/blackberry/haxe";
			mkdir (tmpDir);
			var tmp_name = tmpDir + "/icon.png";
			
			if (icons.updateIcon (86, 86, tmp_name)) {
				
				icon_name = tmp_name;
				
			}
			
		}
		
		if (icon_name != "") {
			
			assets.push (new Asset (icon_name, "icon.png", Asset.TYPE_IMAGE, "icon.png", "1"));
			context.APP_ICON = "icon.png";
			context.HAS_ICON = true;
			
		}
		
	}
	
	
}
