package installers;


import data.NDLL;
import neko.FileSystem;
import neko.io.File;
import neko.io.Path;
import neko.Lib;
import neko.Sys;


class IOSInstaller extends InstallerBase {
	
	
   override function build ():Void {
	   
		//throw "Build not supported on IOS target - please build from Xcode";
	   
		var platformName:String = "iphoneos";
		
		if (targetFlags.exists ("simulator")) {
			
			platformName = "iphonesimulator";
			
		}
		
		var configuration:String = "Release";
		
		if (debug) {
			
			configuration = "Debug";
			
		}
		
		var iphoneVersion:String = defines.get ("IPHONE_VER");
		
		//runCommand (buildDirectory + "/iphone", "xcodebuild", [ "PLATFORM_NAME=" + platformName, "-sdk " + platformName + iphoneVersion, "-configuration " + configuration ] );
		runCommand (buildDirectory + "/iphone", "xcodebuild", [ "-configuration", configuration, "PLATFORM_NAME=" + platformName, "SDKROOT=" + platformName + iphoneVersion ] );
		
	}
	
	
	private override function generateContext ():Void {
		
		super.generateContext ();
		
		context.HAS_ICON = false;
		
		switch (defines.get ("WIN_ORIENTATION")) {
			
			case "landscape" : context.IPHONE_ORIENTATION = "LandscapeLeft";
			case "landscapeLeft" : context.IPHONE_ORIENTATION = "LandscapeLeft";
			case "landscapeRight" : context.IPHONE_ORIENTATION = "LandscapeRight";
			case "portrait" : context.IPHONE_ORIENTATION = "Portrait";
			case "portraitUpsideDown" : context.IPHONE_ORIENTATION = "PortraitUpsideDown";
			
		}
		
		updateIcon ();
		
	}
	
	
	private override function onCreate ():Void {
		
		ndlls.push (new NDLL ("curl", "nme", false));
		ndlls.push (new NDLL ("png", "nme", false));
		ndlls.push (new NDLL ("jpeg", "nme", false));
		ndlls.push (new NDLL ("z", "nme", false));
		
		if (!defines.exists("IPHONE_VER")) {
         		
			var dev_path = "/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/";
         		
			if (neko.FileSystem.exists (dev_path)) {
            			
				var best = "";
            	var files = neko.FileSystem.readDirectory (dev_path);
            	var extract_version = ~/^iPhoneOS(.*).sdk$/;
				
            	for (file in files) {
       				
					if (extract_version.match (file)) {
       					
						var ver = extract_version.matched (1);
						
                  		if (ver > best)
                     		best = ver;
						
               		}

            	}
				
            	if (best != "")
               		defines.set ("IPHONE_VER", best);
			
			}
		
      	}

		//setDefault ("IPHONE_VER", "4.3");
		
	}
	
	
	override function run ():Void { 
		
		if (!targetFlags.exists ("simulator")) {
			
			throw "You must use XCode to install on a real device. Launch XCode or add the -simulator flag to run your project";
			
		}
		
		var configuration:String = "Release";
		
		if (debug) {
			
			configuration = "Debug";
			
		}
		
		var applicationPath:String = buildDirectory + "/iphone/build/" + configuration + "-iphonesimulator/" + defines.get ("APP_TITLE") + ".app";
		//var targetPath:String = Sys.getEnv ("HOME") + "/Library/Application Support/iPhone Simulator/4.3.2/Applications/" + defines.get ("APP_PACKAGE") + "/" + defines.get ("APP_TITLE") + ".app";
		
		//mkdir (targetPath);
		//recursiveCopy (applicationPath, targetPath);
		
		var family:String = "iphone";
		
		if (targetFlags.exists ("ipad")) {
			
			family = "ipad";
			
		}
		
		var launcher:String = NME + "/tools/command-line/iphone/iphonesim";
		
		Sys.command ("chmod", [ "755", launcher ]);
		
		runCommand ("", launcher, [ "launch", FileSystem.fullPath (applicationPath), defines.get ("IPHONE_VER"), family ] );
		//runCommand ("", "open", [ "/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app" ] );
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/iphone/";
		
		mkdir (destination);
		mkdir (destination + "/haxe");
		mkdir (destination + "/haxe/nme/installer");
		
		copyFile (NME + "/tools/command-line/haxe/nme/installer/Assets.hx", destination + "/haxe/nme/installer/Assets.hx");
		recursiveCopy (NME + "/tools/command-line/iphone/haxe", destination + "/haxe");
		recursiveCopy (NME + "/tools/command-line/iphone/Classes", destination + "Classes");
		recursiveCopy (NME + "/tools/command-line/iphone/PROJ.xcodeproj", destination + defines.get ("APP_FILE") + ".xcodeproj");
		copyFile (NME + "/tools/command-line/iphone/PROJ-Info.plist", destination + defines.get ("APP_FILE") + "-Info.plist");
		
		mkdir (destination + "lib");
		
		for (ndll in ndlls) {
			
			copyIfNewer (ndll.getSourcePath ("iPhone", "lib" + ndll.name + ".iphoneos.a"), destination + "lib/lib" + ndll.name + ".iphoneos.a" );
			copyIfNewer (ndll.getSourcePath ("iPhone", "lib" + ndll.name + ".iphonesim.a"), destination + "lib/lib" + ndll.name + ".iphonesim.a" );
			
		}
		
		mkdir (destination + "assets");
		
		for (asset in assets) {
			
			mkdir (Path.directory (destination + "assets/" + asset.id));
			copyIfNewer (asset.sourcePath, destination + "assets/" + asset.id );
			
		}
		
	}
	
	
	function updateIcon () {
		
		var destination:String = buildDirectory + "/iphone/";
		mkdir (destination);
		
		var has_icon = true;
		
		for (i in 0...4) {
			
			var iname = ["Icon.png", "Icon@2x.png", "Icon-72.png", "Icon-Small.png" ][i];
			var size = [57,114,72,50][i];
			var name = destination + "/" + iname;
			
			if (!icons.updateIcon (size, size, name)) {
				
				has_icon = false;
				
			}
			
		}
		
		context.HAS_ICON = has_icon;
		
	}
	
	
	override function useFullClassPaths () { return true; }
	
	
}