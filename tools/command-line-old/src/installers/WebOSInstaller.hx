package installers;


import data.Asset;
import haxe.io.Path;
import helpers.FileHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import helpers.SWFHelper;
import helpers.WebOSHelper;
import sys.io.File;
import sys.FileSystem;


class WebOSInstaller extends InstallerBase {

	
	private var sdkDir:String;
   
	
	override function build ():Void {
		
		var hxml:String = buildDirectory + "/webos/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		ProcessHelper.runCommand ("", "haxe", [ hxml ] );
		
		if (debug) {
			
			FileHelper.copyIfNewer (buildDirectory + "/webos/obj/ApplicationMain-debug", buildDirectory + "/webos/bin/" + defines.get ("APP_FILE"));
			
		} else {
			
			FileHelper.copyIfNewer (buildDirectory + "/webos/obj/ApplicationMain", buildDirectory + "/webos/bin/" + defines.get ("APP_FILE"));
			
		}
		
		WebOSHelper.createPackage (buildDirectory + "/webos", "bin");
		
	}
	
	
	override function clean ():Void {
		
		var targetPath = buildDirectory + "/webos";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	override function generateContext ():Void {
		
		WebOSHelper.initialize (defines);
		
		super.generateContext ();
		
		context.CPP_DIR = buildDirectory + "/webos/obj";
		
		updateIcon ();
		
	}
	
	
	override function run ():Void {
		
		WebOSHelper.install (buildDirectory + "/webos", defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + "_all.ipk");
		WebOSHelper.launch (defines.get ("APP_PACKAGE"));
		
	}
	
	
	override function traceMessages ():Void {
		
		WebOSHelper.trace (defines.get ("APP_PACKAGE"));
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/webos/bin/";
		PathHelper.mkdir (destination);
		
		FileHelper.recursiveCopy (templatePaths[0] + "webos/template", destination, context);
		FileHelper.recursiveCopy (templatePaths[0] + "haxe", buildDirectory + "/webos/haxe", context);
		FileHelper.recursiveCopy (templatePaths[0] + "webos/hxml", buildDirectory + "/webos/haxe", context);
		SWFHelper.generateSWFClasses (NME, swfLibraries, buildDirectory + "/webos/haxe");
		
		for (ndll in ndlls) {
			
			var ndllPath = ndll.getSourcePath ("webOS", ndll.name + "-debug.so");
			var debugExists = FileSystem.exists (ndllPath);
			
			if (!debug || !debugExists) {
				
				ndllPath = ndll.getSourcePath ("webOS", ndll.name + ".so");
				
			}
			
			if (debugExists) {
				
				File.copy (ndllPath, destination + ndll.name + ".so" );
				
			} else {
				
				FileHelper.copyIfNewer (ndllPath, destination + ndll.name + ".so" );
				
			}
			
		}
		
		for (asset in assets) {
			
			PathHelper.mkdir (Path.directory (destination + asset.targetPath));
			
			if (asset.type != Asset.TYPE_TEMPLATE) {
				
				if (asset.targetPath == "/appinfo.json") {
					
					FileHelper.copyFile (asset.sourcePath, destination + asset.targetPath, context);
					
				} else {
					
					// going to root directory now, but should it be a forced "assets" folder later?
					
					FileHelper.copyIfNewer (asset.sourcePath, destination + asset.targetPath);
					
				}
				
			} else {
				
				FileHelper.copyFile (asset.sourcePath, destination + asset.targetPath, context);
				
			}
			
		}
		
	}
	
	
	private function updateIcon ():Void {
		
		var icon_name = icons.findIcon (64, 64);
		
		if (icon_name == "") {
			
			var tmpDir = buildDirectory + "/webos/haxe";
			PathHelper.mkdir (tmpDir);
			var tmp_name = tmpDir + "/icon.png";
			
			if (icons.updateIcon (64, 64, tmp_name)) {
				
				icon_name = tmp_name;
				
			}
			
		}
		
		if (icon_name != "") {
			
			assets.push (new Asset (icon_name, "icon.png", Asset.TYPE_IMAGE, "icon.png", "1"));
			context.APP_ICON = "icon.png";
			
		}
		
	}
	
	
}
