package platforms;


import haxe.io.Path;
import sys.FileSystem;


class BlackBerryPlatform implements IPlatformTool {
	
	
	public function build (project:NMEProject):Void {
		
		initialize (project);
		
		var hxml = project.app.path + "/blackberry/haxe/" + (project.debug ? "debug" : "release") + ".hxml";
		
		ProcessHelper.runCommand ("", "haxe", [ hxml ] );
		
		// need APP_FILE_SAFE alternative
		
		FileHelper.copyIfNewer (project.app.path + "/blackberry/obj/ApplicationMain" + (project.debug ? "-debug" : ""), project.app.path + "/blackberry/bin/" + PathHelper.safeFileName (project.app.file));
		
		BlackBerryHelper.createPackage (project, project.app.path + "/blackberry", "bin/bar-descriptor.xml", project.meta.packageName + "_" + project.meta.version + ".bar");
		
		
	}
	
	
	public function clean (project:NMEProject):Void {
		
		initialize (project);
		
		var targetPath = project.app.path + "/blackberry";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	private function initialize (project:NMEProject):Void {
		
		if (!project.environment.exists ("BLACKBERRY_SETUP")) {
			
			throw "You need to run \"nme setup blackberry\" before you can use the BlackBerry target";
			
		}
		
		BlackBerryHelper.initialize (project);
		
	}
	
	
	public function run (project:NMEProject, arguments:Array <String>):Void {
		
		initialize (project);
		
		BlackBerryHelper.deploy (project, project.app.path + "/blackberry", project.meta.packageName + "_" + project.meta.version + ".bar");
		
	}
	
	
	public function trace (project:NMEProject):Void {
		
		initialize (project);
		
		BlackBerryHelper.trace (project, project.app.path + "/blackberry", project.meta.packageName + "_" + project.meta.version + ".bar");
		
	}
	
	
	public function update (project:NMEProject):Void {
		
		initialize (project);
		
		var cache = new NMEProject ();
		cache.haxeflags = project.haxeflags.copy ();
		cache.assets = project.assets.copy ();
		
		project.assets = new Array <Asset> ();
		
		for (asset in cache.assets) {
			
			var clone = asset.clone ();
			clone.resourceName = "app/native/" + clone.resourceName;
			project.assets.push (clone);
			
		}
		
		if (project.targetFlags.exists ("simulator")) {
			
			project.haxeflags.push ("-D simulator");
			
		}
		
		var context = project.templateContext;
		
		project.haxeflags = cache.haxeflags;
		project.assets = cache.assets;
		
		context.CPP_DIR = project.app.path + "/blackberry/obj";
		context.BLACKBERRY_AUTHOR_ID = BlackBerryHelper.processDebugToken (project, project.app.path + "/blackberry").authorID;
		context.APP_FILE_SAFE = PathHelper.safeFileName (project.app.file);
		
		//updateIcon ();
		
		var destination = project.app.path + "/blackberry/bin/";
		PathHelper.mkdir (destination);
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "blackberry/template", destination, context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", project.app.path + "/blackberry/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "blackberry/hxml", project.app.path + "/blackberry/haxe", context);
		
		SWFHelper.generateSWFClasses (project, project.app.path + "/blackberry/haxe");
		
		var arch = "";
		
		if (project.targetFlags.exists ("simulator")) {
			
			arch = "-x86";
			
		}
		
		var ndlls = project.ndlls.copy ();
		ndlls.push (new NDLL ("libTouchControlOverlay", "nme"));
		
		for (ndll in ndlls) {
			
			FileHelper.copyLibrary (ndll, "BlackBerry", "", ".so", destination, project.debug);
			
		}
		
		var linkedLibraries = [ new NDLL ("libSDL", "nme") ];
		
		for (ndll in linkedLibraries) {
			
			var deviceLib = ndll.name + ".so";
			var simulatorLib = ndll.name + "-x86.so";
			
			if (project.targetFlags.exists ("simulator")) {
				
				if (FileSystem.exists (destination + deviceLib)) {
					
					FileSystem.deleteFile (destination + deviceLib);
					
				}
				
				FileHelper.copyIfNewer (PathHelper.getLibraryPath (ndll, "BlackBerry", "", "-x86.so"), destination + simulatorLib);
				
			} else {
				
				if (FileSystem.exists (destination + simulatorLib)) {
					
					FileSystem.deleteFile (destination + simulatorLib);
					
				}
				
				FileHelper.copyIfNewer (PathHelper.getLibraryPath (ndll, "BlackBerry", "", ".so"), destination + deviceLib);
				
			}
			
		}
		
		for (asset in project.assets) {
			
			PathHelper.mkdir (Path.directory (destination + asset.targetPath));
			
			if (asset.type != AssetType.TEMPLATE) {
				
				// going to root directory now, but should it be a forced "assets" folder later?
				
				FileHelper.copyIfNewer (asset.sourcePath, destination + asset.targetPath);
				
			} else {
				
				FileHelper.copyFile (asset.sourcePath, destination + asset.targetPath, context);
				
			}
			
		}
		
	}
	
	
	/*private function updateIcon ():Void {
		
		context.ICONS = [];
		var sizes = [ 150, 86 ];
		
		for (size in sizes) {
			
			var icon_name = icons.findIcon (size, size);
			
			if (icon_name == "") {
				
				var tmpDir = buildDirectory + "/blackberry/haxe";
				PathHelper.mkdir (tmpDir);
				var tmp_name = tmpDir + "/icon-" + size + ".png";
				
				if (icons.updateIcon (size, size, tmp_name)) {
					
					icon_name = tmp_name;
					
				}
				
			}
			
			if (icon_name != "") {
				
				assets.push (new Asset (icon_name, "icon-" + size + ".png", Asset.TYPE_IMAGE, "icon-" + size + ".png", "1"));
				context.ICONS.push ("icon-" + size + ".png");
				context.HAS_ICON = true;
				
			}
		
		}
		
	}*/
	
	
	public function new () {}
	@ignore public function install (project:NMEProject):Void {}
	@ignore public function uninstall (project:NMEProject):Void {}
	
	
}