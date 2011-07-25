package installers;


import neko.io.Path;
import neko.Lib;
import data.Asset;


class WebOSInstaller extends InstallerBase {
	
	
	override function build ():Void {
		
		var destination:String = buildDirectory + "/webos/bin/";
		mkdir (destination);
		
		context.CPP_DIR = buildDirectory + "/webos/obj";
		
		recursiveCopy (nme + "/install-tool/haxe", buildDirectory + "/webos/haxe");
		recursiveCopy (nme + "/install-tool/webos/hxml", buildDirectory + "/webos/haxe");
		
		var hxml:String = buildDirectory + "/webos/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
		if (debug) {
			
			copyIfNewer (buildDirectory + "/webos/obj/ApplicationMain-debug", buildDirectory + "/webos/bin/" + defines.get ("APP_FILE"));
			
		} else {
			
			copyIfNewer (buildDirectory + "/webos/obj/ApplicationMain", buildDirectory + "/webos/bin/" + defines.get ("APP_FILE"));
			
		}
		
		runCommand (buildDirectory + "/webos", "palm-package", [ "bin", "--use-v1-format" ] );
		
	}
	
	
	override function run ():Void {
		
		runCommand (buildDirectory + "/webos", "palm-install", [ defines.get ("APP_PACKAGE") + "_" + defines.get ("APP_VERSION") + "_all.ipk" ] );
		runCommand ("", "palm-launch", [ defines.get ("APP_PACKAGE") ] );
		
	}
	
	
	override function traceMessages ():Void {
		
		runCommand ("", "palm-log", [ "-f", defines.get ("APP_PACKAGE") ]);
		
	}
	

	override function generateContext ():Void {
		
		super.generateContext ();

      updateIcon();
	}

   function updateIcon() {

      var icon_name = icons.findIcon(64,64);
      if (icon_name=="") {

          var tmpDir = buildDirectory + "/webos/haxe";
          mkdir(tmpDir);
          var tmp_name = tmpDir + "/icon.png";
          if (icons.updateIcon(64,64,tmp_name))
             icon_name = tmp_name;
      }
      if (icon_name!="") {

         assets.push( new data.Asset(icon_name, "icon.png", Asset.TYPE_IMAGE, "icon.png", "1") );
         context.APP_ICON = "icon.png";
      }
   }

	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/webos/bin/";
		mkdir (destination);
		
		recursiveCopy (nme + "/install-tool/webos/template", destination);
		
		for (ndll in ndlls) {
			
			copyIfNewer (ndll.getSourcePath ("webOS", ndll.name + ".so"), destination + ndll.name + ".so" );
			
		}
		
		for (asset in assets) {
			
			mkdir (Path.directory (destination + asset.targetPath));
			copyIfNewer (asset.sourcePath, destination + asset.targetPath );
			
		}
		
	}
	
	
}
