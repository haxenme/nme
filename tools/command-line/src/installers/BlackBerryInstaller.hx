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
		
		runCommand (buildDirectory + "/blackberry", binDirectory + "blackberry-nativepackager", [ "-devMode", "-debugToken", defines.get ("BLACKBERRY_DEBUG_TOKEN"), "-package", defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + ".bar", "bin/bar-descriptor.xml" ]);
		
	}
	
	
	override function generateContext ():Void {
		
		binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/win32/x86/usr/bin/";
		ndlls.push (new NDLL ("libSDL", "nme"));
		ndlls.push (new NDLL ("libTouchControlOverlay", "nme"));
		
		for (asset in assets) {
			
			asset.resourceName = "app/native/" + asset.resourceName;
			
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
		
		runCommand (buildDirectory + "/blackberry", binDirectory + "blackberry-deploy", [ "-installApp", "-launchApp", "-device", defines.get ("BLACKBERRY_DEVICE_IP"), "-password", defines.get ("BLACKBERRY_DEVICE_PASSWORD"), defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + ".bar" ] );
		
	}
	
	
	override function traceMessages ():Void {
		
		runCommand (buildDirectory + "/blackberry", binDirectory + "blackberry-deploy", [ "-getFile", "logs/log", "-", "-device", defines.get ("BLACKBERRY_DEVICE_IP"), "-password", defines.get ("BLACKBERRY_DEVICE_PASSWORD"), defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + ".bar" ] );
		
		//runPalmCommand (false, "log", [ "-f", defines.get ("APP_PACKAGE") ]);
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/blackberry/bin/";
		mkdir (destination);
		
		recursiveCopy (NME + "/tools/command-line/blackberry/template", destination);
		recursiveCopy (NME + "/tools/command-line/haxe", buildDirectory + "/blackberry/haxe");
		recursiveCopy (NME + "/tools/command-line/blackberry/hxml", buildDirectory + "/blackberry/haxe");
		generateSWFClasses (buildDirectory + "/blackberry/haxe");
		
		for (ndll in ndlls) {
			
			var ndllPath = ndll.getSourcePath ("BlackBerry", ndll.name + ".debug.so");
			
			if (!debug || !FileSystem.exists (ndllPath)) {
				
				ndllPath = ndll.getSourcePath ("BlackBerry", ndll.name + ".so");
				
			}
			
			copyIfNewer (ndllPath, destination + ndll.name + ".so" );
			
		}
		
		for (asset in assets) {
			
			if (asset.type != Asset.TYPE_TEMPLATE) {
				
				mkdir (Path.directory (destination + asset.targetPath));
				
				if (asset.targetPath == "/appinfo.json") {
					
					copyFile (asset.sourcePath, destination + asset.targetPath);
					
				} else {
					
					// going to root directory now, but should it be a forced "assets" folder later?
					
					copyIfNewer (asset.sourcePath, destination + asset.targetPath);
					
				}
				
			} else {
				
				copyFile (asset.sourcePath, destination + asset.targetPath);
				
			}
			
		}
		
	}
	
	
	private function updateIcon ():Void {
		
		var icon_name = icons.findIcon (64, 64);
		
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
