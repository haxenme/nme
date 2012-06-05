package installers;


import data.Asset;
import data.NDLL;
import neko.FileSystem;
import neko.io.File;
import neko.io.Path;
import neko.Lib;
import neko.Sys;


class IOSInstaller extends InstallerBase {

   var armv6:Bool;
   var armv7:Bool;
	
	
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
		var commands = [ "-configuration", configuration, "PLATFORM_NAME=" + platformName, "SDKROOT=" + platformName + iphoneVersion ];
		
		if (targetFlags.exists ("simulator")) {
			
			commands.push ("-arch");
			commands.push ("i386");
			
		}
		
		runCommand (buildDirectory + "/iphone", "xcodebuild", commands);
		
	}
	
	
	private override function generateContext ():Void {
		
		super.generateContext ();
		
		context.HAS_ICON = false;
		
		var deployment = Std.parseFloat (iosDeployment);
		var binaries = iosBinaries;
		var devices = iosDevices;

		if (binaries != "fat" && binaries != "armv7" && binaries != "armv6") {
			
			InstallerBase.error ("iOS binaries must be one of: \"fat\", \"armv6\", \"armv7\"");
			
		}
		
		if (devices != "iphone" && devices != "ipad" && devices != "universal") {
			
			InstallerBase.error ("iOS devices must be one of: \"universal\", \"iphone\", \"ipad\"");
			
		}
		
		var iphone = (devices == "universal" || devices == "iphone");
		var ipad = (devices == "universal" || devices == "ipad");
		
		armv6 = (iphone && deployment < 5.0 && binaries != "armv7");
		armv7 = (binaries != "armv6" || !armv6);
		
		var valid_archs = new Array <String> ();
		
		if (armv6)
			valid_archs.push("armv6");
		
		if (armv7)
			valid_archs.push("armv7");
		
		context.CURRENT_ARCHS = "( " + valid_archs.join(",") + ") ";
		
		valid_archs.push("i386");
		
		context.VALID_ARCHS = valid_archs.join(" ");
		context.THUMB_SUPPORT = armv6 ? "GCC_THUMB_SUPPORT = NO;" : "";
		
		var requiredCapabilities = [];
		
		if (armv7 && !armv6)
			requiredCapabilities.push( { name: "armv7", value: true } );
		
		context.REQUIRED_CAPABILITY = requiredCapabilities;
		context.ARMV6 = armv6;
		context.ARMV7 = armv7;
		context.TARGET_DEVICES = switch(devices) { case "universal": "1,2"; case "iphone" : "1"; case "ipad" : "2"; }
		context.DEPLOYMENT = deployment;
		
		switch (defines.get ("WIN_ORIENTATION")) {
			
			case "landscape":
				
				context.IPHONE_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string></array>";
			
			case "portrait":
				
				context.IPHONE_ORIENTATION = "<array><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
			
			default:
				
				context.IPHONE_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
			
		}
		
		context.ADDL_PBX_BUILD_FILE = "";
		context.ADDL_PBX_FILE_REFERENCE = "";
		context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE = "";
		context.ADDL_PBX_FRAMEWORK_GROUP = "";
		
		for (dependencyName in dependencyNames) {
			
			if (Path.extension (dependencyName) == "framework") {
				
				var frameworkID = "11C0000000000018" + Utils.getUniqueID ();
				var fileID = "11C0000000000018" + Utils.getUniqueID ();
				
				context.ADDL_PBX_BUILD_FILE += "		" + frameworkID + " /* " + dependencyName + " in Frameworks */ = {isa = PBXBuildFile; fileRef = " + fileID + " /* " + dependencyName + " */; };\n";
				context.ADDL_PBX_FILE_REFERENCE += "		" + fileID + " /* " + dependencyName + " */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = " + dependencyName + "; path = System/Library/Frameworks/" + dependencyName + "; sourceTree = SDKROOT; };\n";
				context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE += "				" + frameworkID + " /* " + dependencyName + " in Frameworks */,\n";
				context.ADDL_PBX_FRAMEWORK_GROUP += "				" + fileID + " /* " + dependencyName + " */,\n";
				
			}
			
		}
		
		context.HXML_PATH = NME + "/tools/command-line/iphone/haxe/Build.hxml";
		
		updateIcon ();
		
	}
	
	
	private override function onCreate ():Void {
		
		ndlls.push (new NDLL ("curl_ssl", "nme", false));
		ndlls.push (new NDLL ("png", "nme", false));
		ndlls.push (new NDLL ("jpeg", "nme", false));
		ndlls.push (new NDLL ("z", "nme", false));
		
		for (asset in assets) {
			
			asset.resourceName = asset.flatName;
			
		}
		
		if (!defines.exists("IPHONE_VER")) {
         	
			var dev_path = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs";
			
			if (!FileSystem.exists (dev_path)) {
				
				dev_path = "/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/";
				
			}
         	
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
			
			runCommand ("", "open", [ buildDirectory + "/iphone/" + defines.get ("APP_FILE") + ".xcodeproj" ] );
			
		} else {
			
			var configuration:String = "Release";
			
			if (debug) {
				
				configuration = "Debug";
				
			}
			
			var applicationPath:String = buildDirectory + "/iphone/build/" + configuration + "-iphonesimulator/" + defines.get ("APP_TITLE") + ".app";
			var family:String = "iphone";
			
			if (targetFlags.exists ("ipad")) {
				
				family = "ipad";
				
			}
			
			var launcher:String = NME + "/tools/command-line/bin/ios-sim";
			Sys.command ("chmod", [ "+x", launcher ]);
			
			runCommand ("", launcher, [ "launch", FileSystem.fullPath (applicationPath), "--sdk", defines.get ("IPHONE_VER"), "--family", family ] );
			
		}
		
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
		generateSWFClasses (destination + "/haxe");
		
		mkdir (destination + "lib");
		
		for (archID in 0...3) {
			
			var arch = [ "armv6", "armv7", "i386" ][archID];
			
			if (arch == "armv6" && !armv6)
				continue;
			
			if (arch == "armv7" && !armv7)
				continue;
			
			var libExt = [ ".iphoneos.a", ".iphoneos-v7.a", ".iphonesim.a" ][archID];
			
			mkdir (destination + "lib/" + arch);
			mkdir (destination + "lib/" + arch + "-debug");
			
			for (ndll in ndlls) {
				
				var releaseLib = ndll.getSourcePath ("iPhone", "lib" + ndll.name +  libExt);
				var debugLib = ndll.getSourcePath ("iPhone", "lib" + ndll.name + "-debug" + libExt);
				
				var releaseDest = destination + "lib/" + arch + "/lib" + ndll.name + ".a";
				var debugDest = destination + "lib/" + arch + "-debug/lib" + ndll.name + ".a";
				
				copyIfNewer(releaseLib, releaseDest);
				
				if (FileSystem.exists(debugLib)) {
					
					copyIfNewer(debugLib, debugDest);
					
				} else if (FileSystem.exists(debugDest)) {
					
					FileSystem.deleteFile(debugDest);
					
				}
				
			}
			
		}
		
		mkdir (destination + "assets");
		
		for (asset in assets) {
			
			if (asset.type != Asset.TYPE_TEMPLATE) {
				
				mkdir (Path.directory (destination + "assets/" + asset.flatName));
				copyIfNewer (asset.sourcePath, destination + "assets/" + asset.flatName);
				
			} else {
				
				mkdir (Path.directory (destination + asset.targetPath));
				copyFile (asset.sourcePath, destination + asset.targetPath);
				
			}
			
		}
		
	}
	
	
	private function updateIcon () {
		
		var destination:String = buildDirectory + "/iphone/";
		mkdir (destination);
		
		var has_icon = true;
		
		for (i in 0...4) {
			
			var iname = [ "Icon.png", "Icon@2x.png", "Icon-72.png", "Icon-Small.png" ][i];
			var size = [ 57, 114 , 72, 50 ][i];
			
			//var iname = [ "Icon.png", "Icon@2x.png", "Icon-72.png", "Icon-Small.png", "Icon-Small@2x.png", "Icon-Small-50.png", "iTunesArtwork" ][i];
			//var size = [ 57, 114, 72, 29, 58, 50, 512 ][i];
			
			var name = destination + "/" + iname;
			
			if (!icons.updateIcon (size, size, name)) {
				
				has_icon = false;
				
			}
			
		}
		
		context.HAS_ICON = has_icon;
		
	}
	
	
	override function useFullClassPaths () { return true; }
	
	
}