package installers;


import data.NDLL;
import neko.FileSystem;
import neko.io.Path;
import neko.Lib;
import data.Asset;


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
			args.push ("-debugToken");
			args.push (tryFullPath (defines.get ("BLACKBERRY_DEBUG_TOKEN")));
			
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
	
	
	override function generateContext ():Void {
		
		if (InstallTool.isWindows) {
			
			binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/win32/x86/usr/bin/";
			
		} else if (InstallTool.isMac) {
			
			binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/macosx/x86/usr/bin/";
			
		} else {
			
			binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/linux/x86/usr/bin/";
			
		}
		
		ndlls.push (new NDLL ("libSDL", "nme"));
		ndlls.push (new NDLL ("libTouchControlOverlay", "nme"));
		
		for (asset in assets) {
			
			asset.resourceName = "app/native/" + asset.resourceName;
			
		}
		
		if (targetFlags.exists ("simulator")) {
			
			compilerFlags.push ("-D simulator");
			
		}
		
		super.generateContext ();
		
		context.CPP_DIR = buildDirectory + "/blackberry/obj";
		
		updateIcon ();
		
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
			
			deviceIP = "192.168.127.128";
			devicePassword = "playbook";
			
		}
		
		runCommand (buildDirectory + "/blackberry", binDirectory + "blackberry-deploy", [ "-installApp", "-launchApp", "-device", deviceIP, "-password", devicePassword, defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + ".bar" ] );
		
	}
	
	
	override function traceMessages ():Void {
		
		var deviceIP = defines.get ("BLACKBERRY_DEVICE_IP");
		var devicePassword = defines.get ("BLACKBERRY_DEVICE_PASSWORD");
		
		if (targetFlags.exists ("simulator")) {
			
			deviceIP = "192.168.127.128";
			devicePassword = "playbook";
			
		}
		
		runCommand (buildDirectory + "/blackberry", binDirectory + "blackberry-deploy", [ "-getFile", "logs/log", "-", "-device", deviceIP, "-password", devicePassword, defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + ".bar" ] );
		
		//runPalmCommand (false, "log", [ "-f", defines.get ("APP_PACKAGE") ]);
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/blackberry/bin/";
		mkdir (destination);
		
		recursiveCopy (NME + "/tools/command-line/blackberry/template", destination);
		recursiveCopy (NME + "/tools/command-line/haxe", buildDirectory + "/blackberry/haxe");
		recursiveCopy (NME + "/tools/command-line/blackberry/hxml", buildDirectory + "/blackberry/haxe");
		generateSWFClasses (buildDirectory + "/blackberry/haxe");
		
		var arch = "";
		
		if (targetFlags.exists ("simulator")) {
			
			arch = "-x86";
			
		}
		
		for (ndll in ndlls) {
			
			var ndllPath = ndll.getSourcePath ("BlackBerry", ndll.name + "-debug" + arch + ".so");
			var debugExists = FileSystem.exists (ndllPath);
			
			if (!debug || !debugExists) {
				
				ndllPath = ndll.getSourcePath ("BlackBerry", ndll.name + arch + ".so");
				
			}
			
			if (debugExists) {
				
				copyFile (ndllPath, destination + ndll.name + ".so" );
				
			} else {
				
				copyIfNewer (ndllPath, destination + ndll.name + ".so" );
				
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
