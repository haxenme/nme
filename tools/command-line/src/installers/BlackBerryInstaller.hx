package installers;


import data.Asset;
import data.NDLL;
import haxe.io.Path;
import helpers.BlackBerryHelper;
import helpers.FileHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import helpers.SWFHelper;
import sys.io.File;
import sys.FileSystem;


class BlackBerryInstaller extends InstallerBase {

	
	override function build ():Void {
		
		var hxml:String = buildDirectory + "/blackberry/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		ProcessHelper.runCommand ("", "haxe", [ hxml ] );
		
		if (debug) {
			
			FileHelper.copyIfNewer (buildDirectory + "/blackberry/obj/ApplicationMain-debug", buildDirectory + "/blackberry/bin/" + defines.get ("APP_FILE"));
			
		} else {
			
			FileHelper.copyIfNewer (buildDirectory + "/blackberry/obj/ApplicationMain", buildDirectory + "/blackberry/bin/" + defines.get ("APP_FILE"));
			
		}
		
		BlackBerryHelper.createPackage (buildDirectory + "/blackberry", "bin/bar-descriptor.xml", defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + ".bar");
		
	}
	
	
	override function clean ():Void {
		
		var targetPath = buildDirectory + "/blackberry";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	override function generateContext ():Void {
		
		BlackBerryHelper.initialize (defines, targetFlags);
		
		for (asset in assets) {
			
			asset.resourceName = "app/native/" + asset.resourceName;
			
		}
		
		if (targetFlags.exists ("simulator")) {
			
			compilerFlags.push ("-D simulator");
			
		}
		
		super.generateContext ();
		
		context.CPP_DIR = buildDirectory + "/blackberry/obj";
		context.BLACKBERRY_AUTHOR_ID = BlackBerryHelper.getAuthorID (buildDirectory + "/blackberry");
		
		updateIcon ();
		
	}
	
	
	override function onCreate ():Void {
		
		if (!defines.exists ("BLACKBERRY_SETUP")) {
			
			throw "You need to run \"nme setup blackberry\" before you can use the BlackBerry target";
			
		}
		
	}
	
	
	override function run ():Void {
		
		BlackBerryHelper.deploy (buildDirectory + "/blackberry", defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + ".bar");
		
	}
	
	
	override function traceMessages ():Void {
		
		BlackBerryHelper.trace (buildDirectory + "/blackberry", defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + ".bar");
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/blackberry/bin/";
		PathHelper.mkdir (destination);
		
		FileHelper.recursiveCopy (templatePaths[0] + "blackberry/template", destination, context);
		FileHelper.recursiveCopy (templatePaths[0] + "haxe", buildDirectory + "/blackberry/haxe", context);
		FileHelper.recursiveCopy (templatePaths[0] + "blackberry/hxml", buildDirectory + "/blackberry/haxe", context);
		SWFHelper.generateSWFClasses (NME, swfLibraries, buildDirectory + "/blackberry/haxe");
		
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
				
				FileHelper.copyIfNewer (ndll.getSourcePath ("BlackBerry", simulatorLib), destination + simulatorLib);
				
			} else {
				
				if (FileSystem.exists (destination + simulatorLib)) {
					
					FileSystem.deleteFile (destination + simulatorLib);
					
				}
				
				FileHelper.copyIfNewer (ndll.getSourcePath ("BlackBerry", deviceLib), destination + deviceLib);
				
			}
			
		}
		
		for (asset in assets) {
			
			PathHelper.mkdir (Path.directory (destination + asset.targetPath));
			
			if (asset.type != Asset.TYPE_TEMPLATE) {
				
				// going to root directory now, but should it be a forced "assets" folder later?
				
				FileHelper.copyIfNewer (asset.sourcePath, destination + asset.targetPath);
				
			} else {
				
				FileHelper.copyFile (asset.sourcePath, destination + asset.targetPath, context);
				
			}
			
		}
		
	}
	
	
	private function updateIcon ():Void {
		
		var icon_name = icons.findIcon (86, 86);
		
		if (icon_name == "") {
			
			var tmpDir = buildDirectory + "/blackberry/haxe";
			PathHelper.mkdir (tmpDir);
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
