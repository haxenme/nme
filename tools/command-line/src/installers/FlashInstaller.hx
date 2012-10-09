package installers;


import data.Asset;
import haxe.io.Path;
import helpers.AIRHelper;
import helpers.FileHelper;
import helpers.FlashHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import helpers.SWFHelper;
import helpers.ZipHelper;
import sys.io.File;
import sys.FileSystem;


class FlashInstaller extends InstallerBase {
	
	
	override function build ():Void {
		
		var destination = buildDirectory + "/flash/bin";
		var hxml = buildDirectory + "/flash/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		ProcessHelper.runCommand ("", "haxe", [ hxml ] );
		FlashHelper.embedAssets (destination + "/" + defines.get ("APP_FILE") + ".swf", assets);

		if (targetFlags.exists ("web")) {
			
			FileHelper.recursiveCopy (templatePaths[0] + "flash/templates/web", buildDirectory + "/flash/bin", context);
			
		} else if (targetFlags.exists ("chrome")) {
			
			FileHelper.recursiveCopy (templatePaths[0] + "flash/templates/chrome", buildDirectory + "/flash/bin", context);
			
			getIcon (16, buildDirectory + "/flash/bin/icon_16.png");
			getIcon (128, buildDirectory + "/flash/bin/icon_128.png");
			
			//compressToZip (buildDirectory + "/flash/bin/" + defines.get ("APP_FILE") + ".crx");
			
		} else if (targetFlags.exists ("opera")) {
			
			FileHelper.recursiveCopy (templatePaths[0] + "flash/templates/opera", buildDirectory + "/flash/bin", context);
			
			getIcon (16, buildDirectory + "/flash/bin/icon_16.png");
			getIcon (32, buildDirectory + "/flash/bin/icon_32.png");
			getIcon (64, buildDirectory + "/flash/bin/icon_64.png");
			getIcon (128, buildDirectory + "/flash/bin/icon_128.png");
			
			ZipHelper.compress (buildDirectory + "/flash/bin/" + defines.get ("APP_FILE") + ".wgt");
			
		} else if (targetFlags.exists ("air")) {
			
			/*getIcon (16, buildDirectory + "/flash/bin/icon_16.png");
			getIcon (32, buildDirectory + "/flash/bin/icon_32.png");
			getIcon (48, buildDirectory + "/flash/bin/icon_48.png");
			getIcon (128, buildDirectory + "/flash/bin/icon_128.png");*/
			
			FileHelper.copyFile (templatePaths[0] + "flash/templates/air/application.xml", buildDirectory + "/flash/bin/application.xml", context);
			
			var files = [ defines.get ("APP_FILE") + ".swf"/*, "icon_16.png", "icon_32.png", "icon_48.png", "icon_128.png"*/ ];
			
			AIRHelper.build (destination, defines.get ("APP_FILE"), "application.xml", files, debug);
			
		}
		
	}
	
	
	override function clean ():Void {
		
		var targetPath = buildDirectory + "/flash";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	override function generateContext ():Void {
		
		if (defines.exists ("APP_URL") && !targetFlags.exists ("chrome") && !targetFlags.exists ("opera")) {
			
			targetFlags.set ("web", "1");
			
		}
		
		FlashHelper.initialize (defines, targetFlags);
		
		if (targetFlags.exists ("air")) {
			
			AIRHelper.initialize (defines, targetFlags, target, NME);
			compilerFlags.push ("-lib air3");
			
		}
		
		super.generateContext ();

		if (targetFlags.exists ("opera")) {
			
			var packageName = defines.get ("APP_PACKAGE");
			
			context.APP_PACKAGE_HOST = packageName.substr (0, packageName.lastIndexOf ("."));
			context.APP_PACKAGE_NAME = packageName.substr (packageName.lastIndexOf (".") + 1);
			
			var currentDate = Date.now ();
			
			var revisionDate = currentDate.getFullYear () + "-";
			
			var month = currentDate.getMonth ();
			
			if (month < 10) {
				
				revisionDate += "0" + month;
				
			} else {
				
				revisionDate += month;
				
			}
			
			var day = currentDate.getDate ();
			
			if (day < 10) {
				
				revisionDate += "-0" + day;
				
			} else {
				
				revisionDate += "-" + day;
				
			}
			
			context.REVISION_DATE = revisionDate;
			
		}
		
	}
	
	
	private function getIcon (size:Int, targetPath:String):Void {
		
		var icon = icons.findIcon (size, size);
		
		if (icon != "") {
			
			FileHelper.copyIfNewer (icon, targetPath);
			
		} else {
			
			icons.updateIcon (size, size, targetPath);
			
		}
		
	}
	
	
	override function run ():Void {
		
		var destination:String = buildDirectory + "/flash/bin";
		
		if (targetFlags.exists ("air")) {
			
			AIRHelper.run (destination, debug);
			
		} else {
			
			var targetPath = defines.get ("APP_FILE") + ".swf";
			
			if (targetFlags.exists ("web")) {
				
				targetPath = "index.html";
				
			}
			
			FlashHelper.run (destination, targetPath);
			
		}
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/flash/bin/";
		PathHelper.mkdir (destination);
		
		for (asset in assets) {
			
			if (!asset.embed) {
				
				PathHelper.mkdir (Path.directory (destination + asset.targetPath));
				FileHelper.copyIfNewer (asset.sourcePath, destination + asset.targetPath);
				
			}
			
		}
		
		FileHelper.recursiveCopy (templatePaths[0] + "haxe", buildDirectory + "/flash/haxe", context);
		FileHelper.recursiveCopy (templatePaths[0] + "flash/hxml", buildDirectory + "/flash/haxe", context);
		FileHelper.recursiveCopy (templatePaths[0] + "flash/haxe", buildDirectory + "/flash/haxe", context);
		SWFHelper.generateSWFClasses (NME, swfLibraries, buildDirectory + "/flash/haxe");
		
		var usesNME = false;
		
		for (compilerFlag in compilerFlags) {
			
			if (compilerFlag == "-lib nme") {
				
				usesNME = true;
				
			}
			
		}
		
		for (asset in assets) {
			
			if (asset.type == Asset.TYPE_TEMPLATE || !usesNME) {
				
				PathHelper.mkdir (Path.directory (destination + asset.targetPath));
				FileHelper.copyFile (asset.sourcePath, destination + asset.targetPath, context);
				
			}
			
		}
		
	}
	
	
	override private function wantSslCertificate ():Bool {
		
		return false;
		
	}
	
	
}