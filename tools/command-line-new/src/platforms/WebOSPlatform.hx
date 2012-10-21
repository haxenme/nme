package platforms;


import haxe.io.Path;
import sys.FileSystem;


class WebOSPlatform implements IPlatformTool {
	
	
	public function build (project:NMEProject):Void {
		
		var hxml = project.app.path + "/webos/haxe/" + (project.debug ? "debug" : "release") + ".hxml";
		ProcessHelper.runCommand ("", "haxe", [ hxml ] );
		
		FileHelper.copyIfNewer (project.app.path + "/webos/obj/ApplicationMain" + (project.debug ? "-debug" : ""), project.app.path + "/webos/bin/" + project.app.file);
		
		WebOSHelper.createPackage (project, project.app.path + "/webos", "bin");
		
	}
	
	
	public function clean (project:NMEProject):Void {
		
		var targetPath = project.app.path + "/webos";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public function display (project:NMEProject):Void {
	
	
	}
	
	
	public function run (project:NMEProject, arguments:Array <String>):Void {
		
		WebOSHelper.install (project, project.app.path + "/webos");
		WebOSHelper.launch (project);
		
	}
	
	
	public function trace (project:NMEProject):Void {
		
		WebOSHelper.trace (project);
		
	}
	
	
	public function update (project:NMEProject):Void {
		
		var destination = project.app.path + "/webos/bin/";
		PathHelper.mkdir (destination);
		
		var context = project.templateContext;
		context.CPP_DIR = project.app.path + "/webos/obj";
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "webos/template", destination, context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", project.app.path + "/webos/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "webos/hxml", project.app.path + "/webos/haxe", context);
		
		SWFHelper.generateSWFClasses (project, project.app.path + "/webos/haxe");
		
		for (ndll in project.ndlls) {
			
			FileHelper.copyLibrary (ndll, "webOS", "", ".so", destination, project.debug);
			
		}
		
		for (asset in project.assets) {
			
			PathHelper.mkdir (Path.directory (destination + asset.targetPath));
			
			if (asset.type != AssetType.TEMPLATE) {
				
				if (asset.targetPath == "/appinfo.json") {
					
					FileHelper.copyFile (asset.sourcePath, destination + asset.targetPath, context);
					
				} else {
					
					// going to root directory now, but should it be a forced "assets" folder later?
					
					FileHelper.copyIfNewer (asset.sourcePath, destination + asset.targetPath);
					
				}
				
			} else {
				
				FileHelper.copyFile (asset.sourcePath, destination + asset.targetPath, context);
				
			}
			
		}
		
	}
	
	
	/*private function updateIcon ():Void {
		
		var icon_name = icons.findIcon (64, 64);
		
		if (icon_name == "") {
			
			var tmpDir = buildDirectory + "/webos/haxe";
			PathHelper.mkdir (tmpDir);
			var tmp_name = tmpDir + "/icon.png";
			
			if (icons.updateIcon (64, 64, tmp_name)) {
				
				icon_name = tmp_name;
				
			}
			
		}
		
		if (icon_name != "") {
			
			assets.push (new Asset (icon_name, "icon.png", Asset.TYPE_IMAGE, "icon.png", "1"));
			context.APP_ICON = "icon.png";
			
		}
		
	}*/
	
	
	public function new () {}
	@ignore public function install (project:NMEProject):Void {}
	@ignore public function uninstall (project:NMEProject):Void {}
	
	
}