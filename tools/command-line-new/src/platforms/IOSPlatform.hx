package platforms;


import haxe.io.Path;
import sys.FileSystem;


class IOSPlatform implements IPlatformTool {
	
	
	public function build (project:NMEProject):Void {
		
		var targetDirectory = PathHelper.combine (project.app.path, "ios");
		
		IOSHelper.build (project, project.app.path + "/ios");
		
        if (!project.targetFlags.exists ("simulator")) {
            
            var entitlements = targetDirectory + "/" + project.app.file + "/" + project.app.file + "-Entitlements.plist";
            
            IOSHelper.sign (project, targetDirectory + "/bin", entitlements);
            
        }
		
	}
	
	
	public function clean (project:NMEProject):Void {
		
		var targetPath = project.app.path + "/ios";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public function display (project:NMEProject):Void {
	
	
	}
	
	
	private function generateContext (project:NMEProject):Dynamic {
		
		project = project.clone ();
		project.sources = PathHelper.relocatePaths (project.sources, PathHelper.combine (project.app.path, "ios/" + project.app.file + "/haxe"));
		
		var context = project.templateContext;
		
		context.HAS_ICON = false;
		context.HAS_LAUNCH_IMAGE = false;
		context.OBJC_ARC = false;
		
		context.linkedLibraries = [];
		
		for (dependency in project.dependencies) {
			
			if (!StringTools.endsWith (dependency, ".framework")) {
				
				context.linkedLibraries.push (dependency);
				
			}
			
		}
		
		/*var deployment = Std.parseFloat (iosDeployment);
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
			
		}*/
		
		var valid_archs = new Array <String> ();
		var armv6 = false;
		var armv7 = false;
		var devices = "universal";
		var deployment = 5.0;
		var architectures = project.architectures;
		
		if (architectures == null || architectures.length == 0) {
			
			architectures = [ Architecture.ARMV7 ];
			
		}
		
		for (architecture in project.architectures) {
			
			switch (architecture) {
				
				case Architecture.ARMV6: valid_archs.push ("armv6"); armv6 = true;
				case Architecture.ARMV7: valid_archs.push ("armv7"); armv7 = true;
				default:
				
			}
			
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
		
		switch (project.window.orientation) {
			
			case Orientation.PORTRAIT:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
			case Orientation.LANDSCAPE:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string></array>";
			case Orientation.ALL:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
			//case "allButUpsideDown":
				//context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string></array>";
			default:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
			
		}
		
		context.ADDL_PBX_BUILD_FILE = "";
		context.ADDL_PBX_FILE_REFERENCE = "";
		context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE = "";
		context.ADDL_PBX_FRAMEWORK_GROUP = "";
		
		for (dependency in project.dependencies) {
			
			if (Path.extension (dependency) == "framework") {
				
				var frameworkID = "11C0000000000018" + StringHelper.getUniqueID ();
				var fileID = "11C0000000000018" + StringHelper.getUniqueID ();
				
				context.ADDL_PBX_BUILD_FILE += "		" + frameworkID + " /* " + dependency + " in Frameworks */ = {isa = PBXBuildFile; fileRef = " + fileID + " /* " + dependency + " */; };\n";
				context.ADDL_PBX_FILE_REFERENCE += "		" + fileID + " /* " + dependency + " */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = " + dependency + "; path = System/Library/Frameworks/" + dependency + "; sourceTree = SDKROOT; };\n";
				context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE += "				" + frameworkID + " /* " + dependency + " in Frameworks */,\n";
				context.ADDL_PBX_FRAMEWORK_GROUP += "				" + fileID + " /* " + dependency + " */,\n";
				
			}
			
		}
		
		context.HXML_PATH = PathHelper.findTemplate (project.templatePaths, "iphone/PROJ/haxe/Build.hxml");
		context.PRERENDERED_ICON = false;
		
		/*var assets = new Array <Asset> ();
		
		for (asset in project.assets) {
			
			var newAsset = asset.clone ();
			
			assets.push ();
			
		}*/
		
		
		/*for (asset in assets) {
			
			asset.resourceName = asset.flatName;
			
		}*/
		
		//updateIcon ();
		//updateLaunchImage ();
		
		return context;
		
	}
	
	
	public function run (project:NMEProject, arguments:Array <String>):Void {
		
		IOSHelper.launch (project, PathHelper.combine (project.app.path, "ios"));
		
	}
	
	
	public function update (project:NMEProject):Void {
		
		var context = generateContext (project);
		
		var targetDirectory = PathHelper.combine (project.app.path, "ios");
		var projectDirectory = targetDirectory + "/" + project.app.file + "/";
		
		PathHelper.mkdir (targetDirectory);
		PathHelper.mkdir (projectDirectory);
		PathHelper.mkdir (projectDirectory + "/haxe");
		PathHelper.mkdir (projectDirectory + "/haxe/nme/installer");
		
		FileHelper.copyFileTemplate (project.templatePaths, "haxe/nme/installer/Assets.hx", projectDirectory + "/haxe/nme/installer/Assets.hx", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "iphone/PROJ/haxe", projectDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "iphone/PROJ/Classes", projectDirectory + "/Classes", context);
        FileHelper.copyFileTemplate (project.templatePaths, "iphone/PROJ/PROJ-Entitlements.plist", projectDirectory + "/" + project.app.file + "-Entitlements.plist", context);
		FileHelper.copyFileTemplate (project.templatePaths, "iphone/PROJ/PROJ-Info.plist", projectDirectory + "/" + project.app.file + "-Info.plist", context);
		FileHelper.copyFileTemplate (project.templatePaths, "iphone/PROJ/PROJ-Prefix.pch", projectDirectory + "/" + project.app.file + "-Prefix.pch", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "iphone/PROJ.xcodeproj", targetDirectory + "/" + project.app.file + ".xcodeproj", context);
		
		SWFHelper.generateSWFClasses (project, projectDirectory + "/haxe");
		
		PathHelper.mkdir (projectDirectory + "/lib");
		
		var ndlls = project.ndlls.copy ();
		
		ndlls.push (new NDLL ("curl_ssl", "nme"));
		ndlls.push (new NDLL ("png", "nme"));
		ndlls.push (new NDLL ("jpeg", "nme"));
		ndlls.push (new NDLL ("z", "nme"));
		
		for (archID in 0...3) {
			
			var arch = [ "armv6", "armv7", "i386" ][archID];
			
			if (arch == "armv6" && !context.ARMV6)
				continue;
			
			if (arch == "armv7" && !context.ARMV7)
				continue;
			
			var libExt = [ ".iphoneos.a", ".iphoneos-v7.a", ".iphonesim.a" ][archID];
			
			PathHelper.mkdir (projectDirectory + "/lib/" + arch);
			PathHelper.mkdir (projectDirectory + "/lib/" + arch + "-debug");
			
			for (ndll in ndlls) {
				
				if (ndll.haxelib != null) {
					
					var releaseLib = PathHelper.getLibraryPath (ndll, "iPhone", "lib", libExt);
					var debugLib = PathHelper.getLibraryPath (ndll, "iPhone", "lib", libExt);
					var releaseDest = projectDirectory + "/lib/" + arch + "/lib" + ndll.name + ".a";
					var debugDest = projectDirectory + "/lib/" + arch + "-debug/lib" + ndll.name + ".a";
					
					FileHelper.copyIfNewer (releaseLib, releaseDest);
					
					if (FileSystem.exists (debugLib)) {
						
						FileHelper.copyIfNewer (debugLib, debugDest);
						
					} else if (FileSystem.exists (debugDest)) {
						
						FileSystem.deleteFile (debugDest);
						
					}
					
				}
				
			}
			
		}
		
		PathHelper.mkdir (projectDirectory + "/assets");
		
		for (asset in project.assets) {
			
			if (asset.type != AssetType.TEMPLATE) {
				
				//PathHelper.mkdir (Path.directory (projectDirectory + "/assets/" + asset.flatName));
				//FileHelper.copyIfNewer (asset.sourcePath, projectDirectory + "/assets/" + asset.flatName);
				
			} else {
				
				PathHelper.mkdir (Path.directory (projectDirectory + "/" + asset.targetPath));
				FileHelper.copyFile (asset.sourcePath, projectDirectory + "/" + asset.targetPath, context);
				
			}
			
		}
        
        if (project.command == "update") {
            
            ProcessHelper.runCommand ("", "open", [ targetDirectory + "/" + project.app.file + ".xcodeproj" ] );
            
        }
		
	}
	
	/*private function updateIcon () {
		
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
		
	}*/
	
	
	public function new () {}
	@ignore public function install (project:NMEProject):Void {}
	@ignore public function trace (project:NMEProject):Void {}
	@ignore public function uninstall (project:NMEProject):Void {}
	
	
}