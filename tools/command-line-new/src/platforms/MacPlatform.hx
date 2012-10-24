package platforms;


import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;


class MacPlatform implements IPlatformTool {
	
	
	private var applicationDirectory:String;
	private var contentDirectory:String;
	private var executableDirectory:String;
	private var executablePath:String;
	private var targetDirectory:String;
	private var useNeko:Bool;
	
	
	public function build (project:NMEProject):Void {
		
		initialize (project);
		
		var hxml = targetDirectory + "/haxe/" + (project.debug ? "debug" : "release") + ".hxml";
		
		PathHelper.mkdir (targetDirectory);
		ProcessHelper.runCommand ("", "haxe", [ hxml ]);
		
		if (useNeko) {
			
			NekoHelper.createExecutable (project.templatePaths, "Mac", targetDirectory + "/obj/ApplicationMain.n", executablePath);
			NekoHelper.copyLibraries (project.templatePaths, "Mac", executableDirectory);
			
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
	
	
	public function display (project:NMEProject):Void {
		
		var hxml = PathHelper.findTemplate (project.templatePaths, (useNeko ? "neko" : "cpp") + "/hxml/" + (project.debug ? "debug" : "release") + ".hxml");
		
		var context = generateContext (project);
		var contents = File.getContent (hxml);
		var template = new Template (contents);
		
		Sys.println (template.execute (project.templateContext));
		Sys.println ("-D code_completion");
		
	}
	
	
	private function generateContext (project:NMEProject):Dynamic {
		
		var context = project.templateContext;
		context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
		context.CPP_DIR = targetDirectory + "/obj/";
		context.BUILD_DIR = project.app.path + "/mac";
		
		return context;
		
	}
	
	
	private function initialize (project:NMEProject):Void {
		
		targetDirectory = project.app.path + "/mac/cpp";
		
		if (project.targetFlags.exists ("neko") || project.target != PlatformHelper.hostPlatform) {
			
			targetDirectory = project.app.path + "/mac/neko";
			useNeko = true;
			
		}
		
		applicationDirectory = targetDirectory + "/bin/" + project.app.file + ".app";
		contentDirectory = applicationDirectory + "/Contents/Resources";
		executableDirectory = applicationDirectory + "/Contents/MacOS";
		executablePath = executableDirectory + "/" + project.app.file;
		
	}
	
	
	public function run (project:NMEProject, arguments:Array <String>):Void {
		
		if (project.target == PlatformHelper.hostPlatform) {
			
			initialize (project);
			ProcessHelper.runCommand (executableDirectory, "./" + Path.withoutDirectory (executablePath), arguments);
			
		}
		
	}
	
	
	public function update (project:NMEProject):Void {
		
		initialize (project);
		
		var context = generateContext (project);
		
		PathHelper.mkdir (targetDirectory);
		PathHelper.mkdir (targetDirectory + "/obj");
		PathHelper.mkdir (applicationDirectory);
		PathHelper.mkdir (contentDirectory);
		
		SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, (useNeko ? "neko" : "cpp") + "/hxml", targetDirectory + "/haxe", context);
		FileHelper.copyFileTemplate (project.templatePaths, "mac/Info.plist", targetDirectory + "/bin/" + project.app.file + ".app/Contents/Info.plist", context);
		
		for (ndll in project.ndlls) {
			
			FileHelper.copyLibrary (ndll, "Mac", "", ((ndll.haxelib == "" || ndll.haxelib == "hxcpp") ? ".dylib" : ".ndll"), executableDirectory, project.debug);
			
		}
		
		var path = IconHelper.createMacIcon (project, contentDirectory);
		
		if (path != null && path != "") {
			
			context.HAS_ICON = true;
			
		}
		
		for (asset in project.assets) {
			
			if (asset.type != AssetType.TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (contentDirectory + "/" + asset.targetPath));
				FileHelper.copyIfNewer (asset.sourcePath, contentDirectory + "/" + asset.targetPath);
				
			} else {
				
				PathHelper.mkdir (Path.directory (targetDirectory + "/" + asset.targetPath));
				FileHelper.copyFile (asset.sourcePath, targetDirectory + "/" + asset.targetPath, context);
				
			}
			
		}
		
	}
	
	
	public function new () {}
	@ignore public function install (project:NMEProject):Void {}
	@ignore public function trace (project:NMEProject):Void {}
	@ignore public function uninstall (project:NMEProject):Void {}
	
	
}