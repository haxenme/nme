package installers;


import haxe.io.Bytes;
import haxe.crypto.SHA1;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import neko.Lib;
import Sys;
import data.Asset;
import nme.utils.ByteArray;



class FlashInstaller extends InstallerBase {
	
	
	override function build ():Void {
		
		var destination:String = buildDirectory + "/flash/bin";
		var hxml:String = buildDirectory + "/flash/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
		if (targetFlags.exists ("web")) {
			
			recursiveCopy (NME + "/tools/command-line-simple/flash/templates/web", buildDirectory + "/flash/bin");
			
		} else if (targetFlags.exists ("chrome")) {
			
			recursiveCopy (NME + "/tools/command-line-simple/flash/templates/chrome", buildDirectory + "/flash/bin");
			
			getIcon (16, buildDirectory + "/flash/bin/icon_16.png");
			getIcon (128, buildDirectory + "/flash/bin/icon_128.png");
			
			//compressToZip (buildDirectory + "/flash/bin/" + defines.get ("APP_FILE") + ".crx");
			
		} else if (targetFlags.exists ("opera")) {
			
			recursiveCopy (NME + "/tools/command-line-simple/flash/templates/opera", buildDirectory + "/flash/bin");
			
			getIcon (16, buildDirectory + "/flash/bin/icon_16.png");
			getIcon (32, buildDirectory + "/flash/bin/icon_32.png");
			getIcon (64, buildDirectory + "/flash/bin/icon_64.png");
			getIcon (128, buildDirectory + "/flash/bin/icon_128.png");
			
			compressToZip (buildDirectory + "/flash/bin/" + defines.get ("APP_FILE") + ".wgt");
			
		}
		
	}
	
	
	private function compressToZip (path:String):Void {
		throw "Not supported";
	}
	
	
	
	override function generateContext ():Void {
		
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
			
			copyIfNewer (icon, targetPath);
			
		} else {
			
			icons.updateIcon (size, size, targetPath);
			
		}
		
	}
	
	
	override function run ():Void {
		
		var destination:String = buildDirectory + "/flash/bin";
		var player:String;
		
		if (defines.exists ("SWF_PLAYER")) {
			
			player = defines.get ("SWF_PLAYER");
			
		} else {
			
			player = Sys.getEnv ("FLASH_PLAYER_EXE");
			
		}
		
		if (player == null || player == "") {
			
			var dotSlash:String = "./";
			
			if (InstallTool.isWindows) {
				
				runCommand (destination, ".\\" + defines.get ("APP_FILE") + ".swf", []);
				
			} else if (InstallTool.isMac) {
				
				runCommand (destination, "open", [ defines.get ("APP_FILE") + ".swf" ]);
				
			} else {
				
				runCommand (destination, "xdg-open", [ defines.get ("APP_FILE") + ".swf" ]);
				
			}
			
		} else {
			
			runCommand (destination, player, [ defines.get ("APP_FILE") + ".swf" ]);
			
		}
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/flash/bin/";
		mkdir (destination);
		
		for (asset in assets) {
			
			if (!asset.embed) {
				
				mkdir (Path.directory (destination + asset.targetPath));
				copyIfNewer (asset.sourcePath, destination + asset.targetPath);
				
			}
			
		}
		
		recursiveCopy (NME + "/tools/command-line-simple/haxe", buildDirectory + "/flash/haxe");
		recursiveCopy (NME + "/tools/command-line-simple/flash/hxml", buildDirectory + "/flash/haxe");
		recursiveCopy (NME + "/tools/command-line-simple/flash/haxe", buildDirectory + "/flash/haxe");
		generateSWFClasses (NME + "/tools/command-line-simple/resources/SWFClass.mtt", buildDirectory + "/flash/haxe");
		
		for (asset in assets) {
			
			if (asset.type == Asset.TYPE_TEMPLATE) {
				
				copyFile (asset.sourcePath, destination + asset.targetPath);
				
			}
			
		}
		
	}

   override private function wantSslCertificate ():Bool {
      return false;
   }

	
	
}

