package installers;


import neko.io.Path;
import neko.Lib;


class WebOSInstaller extends InstallerBase {
	
	
	override function build ():Void {
		
		var destination:String = buildDirectory + "/webos/" + defines.get ("APP_FILE") + "/";
		mkdir (destination);
		
		context.CPP_DIR = buildDirectory + "/webos/bin";
		
		recursiveCopy (nme + "/install-tool/haxe", buildDirectory + "/webos/haxe");
		recursiveCopy (nme + "/install-tool/webos/hxml", buildDirectory + "/webos/haxe");
		recursiveCopy (nme + "/install-tool/webos/template", destination);
		
		var hxml:String = buildDirectory + "/webos/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
		var destination:String = buildDirectory + "/webos/" + defines.get ("APP_FILE") + "/" + defines.get ("APP_FILE");
		
		if (debug) {
			
			copyIfNewer (buildDirectory + "/webos/bin/ApplicationMain-debug", destination );
			
		} else {
			
			copyIfNewer (buildDirectory + "/webos/bin/ApplicationMain", destination );
			
		}
		
	}
	
	
	override function run ():Void {
		
		runCommand (buildDirectory + "/webos", "palm-install", [ defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + "_all.ipk" ] );
		runCommand ("", "palm-launch", [ defines.get ("APP_PACKAGE") ] );
		runCommand ("", "palm-log", [ "-f", defines.get ("APP_PACKAGE") ]);
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/webos/" + defines.get ("APP_FILE") + "/";
		mkdir (destination);
		
		for (ndll in ndlls) {
			
			copyIfNewer (ndll.getSourcePath ("webOS", ndll.name + ".so"), destination + ndll.name + ".so" );
			
		}
		
		for (asset in assets) {
			
			mkdir (Path.directory (destination + asset.targetPath));
			copyIfNewer (asset.sourcePath, destination + asset.targetPath );
			
		}
		
		runCommand (buildDirectory + "/webos", "palm-package", [ defines.get ("APP_FILE"), "--use-v1-format" ] );
		
	}
	
	
}
