package platforms;


import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;


class HTML5Platform implements IPlatformTool {
	
	
	private var outputDirectory:String;
	private var outputFile:String;
	
	
	public function build (project:NMEProject):Void {
		
		initialize (project);
		
		if (project.app.main != null) {
			
			var hxml = outputDirectory + "/haxe/" + (project.debug ? "debug" : "release") + ".hxml";
			ProcessHelper.runCommand ("", "haxe", [ hxml ] );
			
		}
		
		if (project.targetFlags.exists ("minify")) {
			
			var sourceFile = project.app.path + "/bin/" + project.app.file + ".js";
			var tempFile = project.app.path + "/bin/_" + project.app.file + ".js";
			
			FileSystem.rename (sourceFile, tempFile);
			
			if (project.targetFlags.exists ("yui")) {
				
				ProcessHelper.runCommand ("", "java", [ "-jar", PathHelper.findTemplate (project.templatePaths, "bin/yuicompressor-2.4.7.jar"), "-o", sourceFile, tempFile ]);
				
			} else {
				
				var args = [ "-jar", PathHelper.findTemplate (project.templatePaths, "bin/compiler.jar"), "--js", tempFile, "--js_output_file", sourceFile ];
				
				if (!LogHelper.verbose) {
					
					args.push ("--jscomp_off=uselessCode");
					
				}
				
				ProcessHelper.runCommand ("", "java", args);
				
			}
			
			FileSystem.deleteFile (tempFile);
			
		}
		
		if (project.target != Platform.HTML5 && project.command != "update") {
			
			//CordovaHelper.build (project, outputDirectory + "/bin", project.debug);
			
		}
		
	}
	
	
	public function clean (project:NMEProject):Void {
		
		var targetPath = project.app.path + "/html5";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public function display (project:NMEProject):Void {
	
	
	}
	
	
	private function generateFontData (project:NMEProject, font:Asset, destination:String):String {
		
		var sourcePath = font.sourcePath;
		var targetPath = destination + font.targetPath;
		
		if (!FileSystem.exists (FileSystem.fullPath (sourcePath) + ".hash")) {
			
			ProcessHelper.runCommand (Path.directory (targetPath), "neko", [ PathHelper.findTemplate (project.templatePaths, "html5/hxswfml.n"), "ttf2hash", FileSystem.fullPath (sourcePath), "-glyphs", "32-255" ] );
			
		}
		
		return "-resource " + FileSystem.fullPath (sourcePath) + ".hash@NME_" + font.flatName;
		
	}
	
	
	private function initialize (project:NMEProject):Void {
		
		outputDirectory = project.app.path + "/html5/";
		
		if (project.target == Platform.HTML5) {
			
			outputDirectory += "web";
			
		} else {
			
			outputDirectory += Std.string (project.target).toLowerCase ();
			
		}
		
		outputFile = outputDirectory + "/bin/" + project.app.file + ".js";
		
		if (project.target != Platform.HTML5) {
			
			//outputFile = outputDirectory + "/bin/" + CordovaHelper.contentPath + defines.get ("APP_FILE") + ".js";
			
		}
		
	}
	
	
	public function run (project:NMEProject, arguments:Array < String > ):Void {
		
		initialize (project);
		
		if (project.target == Platform.HTML5) {
			
			if (project.app.url != "") {
				
				ProcessHelper.openURL (project.app.url);		
				
			} else {
				
				ProcessHelper.openFile (project.app.path + "/html5/web/bin", "index.html");
				
			}
			
		} else {
			
			//CordovaHelper.launch (outputDirectory + "/html5/" + Std.string (project.target).toLowerCase () + "/bin", project.debug);
			
		}
		
	}
	
	
	public function update (project:NMEProject):Void {
		
		initialize (project);
		
		project = project.clone ();
		
		if (project.targetFlags.exists ("html5")) {
			
			project.haxeflags.push ("-lib cordova");
			//CordovaHelper.initialize (defines, targetFlags, target, NME);
			
		}
		
		
		
		var context = project.templateContext;
		
		context.OUTPUT_DIR = outputDirectory;
		context.OUTPUT_FILE = outputFile;
		
		//CordovaHelper.updateIcon (buildDirectory + "/html5/" + target, icons, assets, context);
		
		var destination = outputDirectory + "/bin/";
		PathHelper.mkdir (destination);
		
		if (project.target != Platform.HTML5) {
			
			//CordovaHelper.create ("", destination, context);
			//destination += CordovaHelper.contentPath;
			
		}
		
		for (asset in project.assets) {
			
			if (asset.type != AssetType.TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (destination + asset.targetPath));
				
				if (asset.type != AssetType.FONT) {
					
					// going to root directory now, but should it be a forced "assets" folder later?
					
					if (project.target == Platform.HTML5) {
						
						FileHelper.copyIfNewer (asset.sourcePath, destination + asset.targetPath);
						
					} else {
						
						File.copy (asset.sourcePath, destination + asset.targetPath);
						
					}
					
				} else {
					
					project.haxeflags.push (generateFontData (project, asset, destination));
					
				}
				
			}
			
		}
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/template", destination, context);
		
		if (project.app.main != null) {
			
			FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", outputDirectory + "/haxe", context);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/haxe", outputDirectory + "/haxe", context);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/hxml", outputDirectory + "/haxe", context);
			
		}
		
		for (asset in project.assets) {
			
			if (asset.type == AssetType.TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (destination + asset.targetPath));
				FileHelper.copyFile (asset.sourcePath, destination + asset.targetPath, context);
				
			}
			
		}
		
		if (project.target == Platform.IOS && project.command == "update") {
			
			build (project);
            ProcessHelper.runCommand ("", "open", [ destination + "../" + project.app.file + ".xcodeproj" ] );
			
		}
		
	}
	
	
	public function new () {}
	@ignore public function install (project:NMEProject):Void {}
	@ignore public function trace (project:NMEProject):Void {}
	@ignore public function uninstall (project:NMEProject):Void {}
	
	
}