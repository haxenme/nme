package platforms;


import haxe.io.Path;
import sys.FileSystem;


class LinuxPlatform implements IPlatformTool {
	
	
	private var applicationDirectory:String;
	private var executablePath:String;
	private var is64:Bool;
	private var targetDirectory:String;
	private var useNeko:Bool;
	
	
	public function build (project:NMEProject):Void {
		
		initialize (project);
		
		var hxml = targetDirectory + "/haxe/" + (project.debug ? "debug" : "release") + ".hxml";
		
		PathHelper.mkdir (targetDirectory);
		ProcessHelper.runCommand ("", "haxe", [ hxml ]);
		
		if (useNeko) {
			
			NekoHelper.createExecutable (project.templatePaths, "Linux" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
			NekoHelper.copyLibraries (project.templatePaths, "Linux" + (is64 ? "64" : ""), applicationDirectory);
			
		} else {
			
			FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), executablePath);
			
		}
		
		if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
			
			ProcessHelper.runCommand ("", "chmod", [ "755", executablePath ]);
			
		}
		
	}
	
	
	public function clean (project:NMEProject):Void {
		
		initialize (project);
		
		if (FileSystem.exists (targetDirectory)) {
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	private function initialize (project:NMEProject):Void {
		
		for (architecture in architectures) {
			
			if (architecture == Architecture.X64) {
				
				is64 = true;
				
			}
			
		}
		
		targetDirectory = project.app.path + "/linux/cpp";
		
		if (project.targetFlags.exists ("neko") || project.target != PlatformHelper.hostPlatform) {
			
			targetDirectory = project.app.path + "/linux/neko";
			useNeko = true;
			
		}
		
		applicationDirectory = targetDirectory + "/bin/";
		executablePath = applicationDirectory + "/" + project.app.file;
		
	}
	
	
	public function run (project:NMEProject, arguments:Array <String>):Void {
		
		if (project.target == PlatformHelper.hostPlatform) {
			
			initialize (project);
			ProcessHelper.runCommand (executableDirectory, "./" + Path.withoutDirectory (executablePath), arguments);
			
		}
		
	}
	
	
	public function update (project:NMEProject):Void {
		
		initialize (project);
		
		var context = project.templateContext;
		context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
		context.CPP_DIR = targetDirectory + "/obj/";
		context.BUILD_DIR = project.app.path + "/linux";
		
		PathHelper.mkdir (targetDirectory);
		PathHelper.mkdir (targetDirectory + "/obj");
		PathHelper.mkdir (applicationDirectory);
		
		SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, (useNeko ? "neko" : "cpp") + "/hxml", targetDirectory + "/haxe", context);
		
		for (ndll in project.ndlls) {
			
			FileHelper.copyLibrary (ndll, "Linux" + (is64 ? "64" : ""), "", ((ndll.haxelib == "" || ndll.haxelib == "hxcpp") ? ".dso" : ".ndll"), executableDirectory, project.debug);
			
		}
		
		/*var path = IconHelper.createMacIcon (project, contentDirectory);
		
		if (path != null && path != "") {
			
			context.HAS_ICON = true;
			
		}*/
		
		for (asset in project.assets) {
			
			if (asset.type != AssetType.TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (applicationDirectory + "/" + asset.targetPath));
				FileHelper.copyIfNewer (asset.sourcePath, applicationDirectory + "/" + asset.targetPath);
				
			} else {
				
				PathHelper.mkdir (Path.directory (applicationDirectory + "/" + asset.targetPath));
				FileHelper.copyFile (asset.sourcePath, applicationDirectory + "/" + asset.targetPath, context);
				
			}
			
		}
		
	}
	
	
	/*private function updateIcon () {
		
		if (!InstallTool.isMac && icons.hasIcons ()) {
			
			var icon_name = icons.findIcon (32, 32);
			
			if (icon_name == "") {
				
				PathHelper.mkdir(targetDir + "/haxe");
				
				var tmp_name = targetDir + "/haxe/icon.png";
				
				if (icons.updateIcon (32, 32, tmp_name)) {
					
					icon_name = tmp_name;
					
				}
				
			}
			
			if (icon_name != "") {
				
				assets.push (new Asset (icon_name, "icon.png", Asset.TYPE_IMAGE, "icon.png", "1"));
				context.WIN_ICON = "icon.png";
				
			}
			
		}
		
	}*/
	
	
	public function new () {}
	@ignore public function install (project:NMEProject):Void {}
	@ignore public function trace (project:NMEProject):Void {}
	@ignore public function uninstall (project:NMEProject):Void {}
	
	
}