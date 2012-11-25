package platforms;


import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;


class BlackBerryPlatform implements IPlatformTool {
	
	
	public function build (project:NMEProject):Void {
		
		initialize (project);
		
		var hxml = project.app.path + "/blackberry/haxe/" + (project.debug ? "debug" : "release") + ".hxml";
		
		ProcessHelper.runCommand ("", "haxe", [ hxml ] );
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
	
	
	public function display (project:NMEProject):Void {
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "blackberry/hxml/" + (project.debug ? "debug" : "release") + ".hxml");
		
		var context = project.templateContext;
		context.CPP_DIR = project.app.path + "/blackberry/obj";
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	private function initialize (project:NMEProject):Void {
		
		if (!project.environment.exists ("BLACKBERRY_SETUP")) {
			
			LogHelper.error ("You need to run \"nme setup blackberry\" before you can use the BlackBerry target");
			
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
		
		project = project.clone ();
		initialize (project);
		
		for (asset in project.assets) {
			
			asset.resourceName = "app/native/" + asset.resourceName;
			
		}
		
		if (project.targetFlags.exists ("simulator")) {
			
			project.haxeflags.push ("-D simulator");
			
		}
		
		var context = project.templateContext;
		
		context.CPP_DIR = project.app.path + "/blackberry/obj";
		context.BLACKBERRY_AUTHOR_ID = BlackBerryHelper.processDebugToken (project, project.app.path + "/blackberry").authorID;
		context.APP_FILE_SAFE = PathHelper.safeFileName (project.app.file);
		
		var destination = project.app.path + "/blackberry/bin/";
		PathHelper.mkdir (destination);
		
		context.ICONS = [];
		context.HAS_ICON = false;
		
		for (size in [ 114, 86 ]) {
			
			if (IconHelper.createIcon (project.icons, size, size, PathHelper.combine (destination, "icon-" + size + ".png"))) {
				
				context.ICONS.push ("icon-" + size + ".png");
				context.HAS_ICON = true;
				
			}
			
		}
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "blackberry/template", destination, context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", project.app.path + "/blackberry/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "blackberry/hxml", project.app.path + "/blackberry/haxe", context);
		
		//SWFHelper.generateSWFClasses (project, project.app.path + "/blackberry/haxe");
		
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
				
				FileHelper.copyAssetIfNewer (asset, destination + asset.targetPath);
				
			} else {
				
				FileHelper.copyAsset (asset, destination + asset.targetPath, context);
				
			}
			
		}
		
	}
	
	
	public function new () {}
	@ignore public function install (project:NMEProject):Void {}
	@ignore public function uninstall (project:NMEProject):Void {}
	
	
}