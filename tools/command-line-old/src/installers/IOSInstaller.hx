package installers;


import data.Asset;
import data.NDLL;
import haxe.io.Path;
import helpers.FileHelper;
import helpers.IOSHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import helpers.SWFHelper;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;


class IOSInstaller extends InstallerBase {
	
	
   	private var armv6:Bool;
   	private var armv7:Bool;
	
	
   	override function build ():Void {
		
		IOSHelper.build (buildDirectory + "/ios", debug);
		
        if (!targetFlags.exists ("simulator")) {
            
            var entitlements = buildDirectory + "/ios/" + defines.get("APP_FILE") + "/" + defines.get("APP_FILE") + "-Entitlements.plist";
            
            IOSHelper.sign (buildDirectory + "/ios/bin", entitlements, debug);
            
        }
        
	}
	
	
	override function clean ():Void {
		
		var targetPath = buildDirectory + "/ios";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	private override function generateContext ():Void {
		
		IOSHelper.initialize (defines, targetFlags, NME);
		
		super.generateContext ();

		context.HAS_ICON = false;
		context.HAS_LAUNCH_IMAGE = false;
		context.OBJC_ARC = false;
		
		context.linkedLibraries = [];
		
		for (dependencyName in dependencyNames) {
			
			if (!StringTools.endsWith (dependencyName, ".framework")) {
				
				context.linkedLibraries.push (dependencyName);
				
			}
			
		}
		
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
		
		armv6 = ((iphone && deployment < 5.0 && Std.parseInt (defines.get ("IPHONE_VER")) < 6) || binaries == "armv7");
		armv7 = (binaries != "armv6" || !armv6 || ipad);
		
		var valid_archs = new Array <String> ();
		
		if (armv6) {
			
			valid_archs.push("armv6");
			
		}
		
		if (armv7) {
			
			valid_archs.push("armv7");
			
		}

		if (iosCompiler == "llvm" || iosCompiler == "clang") {
			
			context.OBJC_ARC = true;
			
		}

		context.CURRENT_ARCHS = "( " + valid_archs.join(",") + ") ";
		
		valid_archs.push ("i386");
		
		context.VALID_ARCHS = valid_archs.join(" ");
		context.THUMB_SUPPORT = armv6 ? "GCC_THUMB_SUPPORT = NO;" : "";
		
		var requiredCapabilities = [];
		
		if (armv7 && !armv6) {
			
			requiredCapabilities.push( { name: "armv7", value: true } );
			
		}
		
		context.REQUIRED_CAPABILITY = requiredCapabilities;
		context.ARMV6 = armv6;
		context.ARMV7 = armv7;
		context.TARGET_DEVICES = switch(devices) { case "universal": "1,2"; case "iphone" : "1"; case "ipad" : "2"; }
		context.DEPLOYMENT = deployment;
		
		switch (defines.get ("WIN_ORIENTATION")) {
			
			case "portrait":
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
			case "landscape":
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string></array>";
			case "all":
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
			case "allButUpsideDown":
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string></array>";
			default:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
			
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
		
		context.HXML_PATH = templatePaths[0] + "iphone/PROJ/haxe/Build.hxml";
		updateIcon ();
		updateLaunchImage ();
		
	}
	
	
	private override function onCreate ():Void {
		
		ndlls.push (new NDLL ("curl_ssl", "nme", false));
		ndlls.push (new NDLL ("png", "nme", false));
		ndlls.push (new NDLL ("jpeg", "nme", false));
		ndlls.push (new NDLL ("z", "nme", false));
		
		for (asset in assets) {
			
			asset.resourceName = asset.flatName;
			
		}
		
	}
	
	
	override function run ():Void {
        
        IOSHelper.launch (buildDirectory + "/ios", debug);
        
	}
	
	
	override function update ():Void {
		
		var destination = buildDirectory + "/ios/";
		var projDestination = destination + defines.get ("APP_FILE") + "/";
		
		PathHelper.mkdir (destination);
		PathHelper.mkdir (projDestination);
		PathHelper.mkdir (projDestination + "/haxe");
		PathHelper.mkdir (projDestination + "/haxe/nme/installer");
		
		FileHelper.copyFile (templatePaths[0] + "haxe/nme/installer/Assets.hx", projDestination + "/haxe/nme/installer/Assets.hx", context);
		FileHelper.recursiveCopy (templatePaths[0] + "iphone/PROJ/haxe", projDestination + "/haxe", context);
		FileHelper.recursiveCopy (templatePaths[0] + "iphone/PROJ/Classes", projDestination + "Classes", context);
        FileHelper.copyFile (templatePaths[0] + "iphone/PROJ/PROJ-Entitlements.plist", projDestination + defines.get ("APP_FILE") + "-Entitlements.plist", context);
		FileHelper.copyFile (templatePaths[0] + "iphone/PROJ/PROJ-Info.plist", projDestination + defines.get ("APP_FILE") + "-Info.plist", context);
		FileHelper.copyFile (templatePaths[0] + "iphone/PROJ/PROJ-Prefix.pch", projDestination + defines.get ("APP_FILE") + "-Prefix.pch", context);
		FileHelper.recursiveCopy (templatePaths[0] + "iphone/PROJ.xcodeproj", destination + defines.get ("APP_FILE") + ".xcodeproj", context);
		SWFHelper.generateSWFClasses (NME, swfLibraries, projDestination + "/haxe");
		
		PathHelper.mkdir (projDestination + "lib");
		
		for (archID in 0...3) {
			
			var arch = [ "armv6", "armv7", "i386" ][archID];
			
			if (arch == "armv6" && !armv6)
				continue;
			
			if (arch == "armv7" && !armv7)
				continue;
			
			var libExt = [ ".iphoneos.a", ".iphoneos-v7.a", ".iphonesim.a" ][archID];
			
			PathHelper.mkdir (projDestination + "lib/" + arch);
			PathHelper.mkdir (projDestination + "lib/" + arch + "-debug");
			
			for (ndll in ndlls) {
				
				if (ndll.haxelib != null) {
					
					var releaseLib = ndll.getSourcePath ("iPhone", "lib" + ndll.name +  libExt);
					var debugLib = ndll.getSourcePath ("iPhone", "lib" + ndll.name + "-debug" + libExt);
					var releaseDest = projDestination + "lib/" + arch + "/lib" + ndll.name + ".a";
					var debugDest = projDestination + "lib/" + arch + "-debug/lib" + ndll.name + ".a";
					
					FileHelper.copyIfNewer (releaseLib, releaseDest);
					
					if (FileSystem.exists (debugLib)) {
						
						FileHelper.copyIfNewer (debugLib, debugDest);
						
					} else if (FileSystem.exists (debugDest)) {
						
						FileSystem.deleteFile (debugDest);
						
					}
					
				}
				
			}
			
		}
		
		PathHelper.mkdir (projDestination + "assets");
		
		for (asset in assets) {
			
			if (asset.type != Asset.TYPE_TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (projDestination + "assets/" + asset.flatName));
				FileHelper.copyIfNewer (asset.sourcePath, projDestination + "assets/" + asset.flatName);
				
			} else {
				
				PathHelper.mkdir (Path.directory (projDestination + asset.targetPath));
				FileHelper.copyFile (asset.sourcePath, projDestination + asset.targetPath, context);
				
			}
			
		}
        
        if (command == "update") {
            
            ProcessHelper.runCommand ("", "open", [ buildDirectory + "/ios/" + defines.get("APP_FILE") + ".xcodeproj" ] );
            
        }
        
	}
	
	
	private function updateIcon () {
		
		var destination = buildDirectory + "/ios";
		PathHelper.mkdir (destination);
		
		var has_icon = true;
		
		for (i in 0...4) {
			
			var iname = [ "Icon.png", "Icon@2x.png", "Icon-72.png", "Icon-72@2x.png" ][i];
			var size = [ 57, 114 , 72, 144 ][i];
			var name = destination + "/" + iname;
			
			if (!icons.updateIcon (size, size, name)) {
				
				has_icon = false;
				
			}
			
		}
		
		context.HAS_ICON = has_icon;
		
	}
	
	
	private function updateLaunchImage () {
		
		var destination = buildDirectory + "/ios";
		PathHelper.mkdir (destination);
		
		var has_launch_image = false;
		if (launchImages.length > 0) has_launch_image = true;

		for (launchImage in launchImages) {
			
			var splitPath = launchImage.name.split ("/");
			var path = destination + "/" + splitPath[splitPath.length - 1];
			FileHelper.copyFile (launchImage.name, path, context, false);
			
		}

		context.HAS_LAUNCH_IMAGE = has_launch_image;
		
	}
	
	
	override function useFullClassPaths () { return true; }
	
	
}
