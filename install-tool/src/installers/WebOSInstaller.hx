package installers;


import neko.io.Path;
import neko.Lib;
import data.Asset;


class WebOSInstaller extends InstallerBase {

	
	private var sdkDir:String;
   
	
	override function build ():Void {
		
		var destination:String = buildDirectory + "/webos/bin/";
		mkdir (destination);
		
		context.CPP_DIR = buildDirectory + "/webos/obj";
		
		recursiveCopy (NME + "/install-tool/haxe", buildDirectory + "/webos/haxe");
		recursiveCopy (NME + "/install-tool/webos/hxml", buildDirectory + "/webos/haxe");
		
		var hxml:String = buildDirectory + "/webos/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
		if (debug) {
			
			copyIfNewer (buildDirectory + "/webos/obj/ApplicationMain-debug", buildDirectory + "/webos/bin/" + defines.get ("APP_FILE"));
			
		} else {
			
			copyIfNewer (buildDirectory + "/webos/obj/ApplicationMain", buildDirectory + "/webos/bin/" + defines.get ("APP_FILE"));
			
		}
		
		runPalmCommand (true, "package" ,[ "bin" ] );
		
	}
	
	
	override function generateContext ():Void {
		
		sdkDir = "";
		
		if (defines.exists ("PalmSDK")) {
			
			sdkDir = defines.get ("PalmSDK");
			
		} else {
			
			if (InstallTool.isWindows) {
				
				sdkDir = "c:\\Program Files (x86)\\HP webOS\\SDK\\";
				
			} else {
				
				sdkDir = "/opt/PalmSDK/Current/";
				
			}
			
		}
		
		super.generateContext ();
		
		updateIcon ();
		
	}
	
	
	override function run ():Void {
		
		runPalmCommand (true, "install", [ defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + "_all.ipk" ] );
		runPalmCommand (false, "launch", [ defines.get ("APP_PACKAGE") ] );
		
	}
	
	
	private function runPalmCommand (inBinDir:Bool, inCommand:String, args:Array<String>):Void {
		
		var dir = inBinDir ? buildDirectory + "/webos" : "";
		
		if (InstallTool.isWindows) {
			
			var jar_file = defines.get("PalmSDK") + "\\share\\jars\\webos-tools.jar";
			var new_args = ["-Dpalm.command=palm-" + inCommand , "-jar", jar_file].concat(args);
			runCommand (dir, "java" , new_args );
			
		} else {
			
			runCommand (dir, sdkDir + "/bin/palm-" + inCommand, args);
			
		}
		
	}
	
	
	override function traceMessages ():Void {
		
		runPalmCommand (false, "log", [ "-f", defines.get ("APP_PACKAGE") ]);
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/webos/bin/";
		mkdir (destination);
		
		recursiveCopy (NME + "/install-tool/webos/template", destination);
		
		for (ndll in ndlls) {
			
			copyIfNewer (ndll.getSourcePath ("webOS", ndll.name + ".so"), destination + ndll.name + ".so" );
			
		}
		
		for (asset in assets) {
			
			mkdir (Path.directory (destination + asset.targetPath));
			
			if (asset.targetPath == "/appinfo.json") {
				
				copyFile (asset.sourcePath, destination + asset.targetPath);
				
			} else {
				
				copyIfNewer (asset.sourcePath, destination + asset.targetPath);
				
			}
			
		}
		
	}
	
	
	private function updateIcon ():Void {
		
		var icon_name = icons.findIcon (64, 64);
		
		if (icon_name == "") {
			
			var tmpDir = buildDirectory + "/webos/haxe";
			mkdir (tmpDir);
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
