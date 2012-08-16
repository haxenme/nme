package installers;


import data.Asset;
import haxe.io.Path;
import helpers.CordovaHelper;
import helpers.FileHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;


/**
 * ...
 * @author Joshua Granick
 */

class HTML5Installer extends InstallerBase {
	
	
	private var outputDirectory:String;
	private var outputFile:String;
	
	
	override function build ():Void {
		
		if (defines.exists ("APP_MAIN")) {
			
			var hxml:String = outputDirectory + "/haxe/" + (debug ? "debug" : "release") + ".hxml";
			ProcessHelper.runCommand ("", "haxe", [ hxml ] );
			
		}
		
		if (targetFlags.exists ("minify")) {
			
			if (defines.exists ("JAVA_HOME")) {
				
				Sys.putEnv ("JAVA_HOME", defines.get ("JAVA_HOME"));
				
			}
			
			var sourceFile = outputDirectory + "/bin/" + defines.get ("APP_FILE") + ".js";
			var tempFile = outputDirectory + "/bin/_" + defines.get ("APP_FILE") + ".js";
			
			FileSystem.rename (sourceFile, tempFile);
			
			if (targetFlags.exists ("yui")) {
				
				ProcessHelper.runCommand ("", "java", [ "-jar", NME + "/tools/command-line/bin/yuicompressor-2.4.7.jar", "-o", sourceFile, tempFile ]);
				
			} else {
				
				var args = [ "-jar", NME + "/tools/command-line/bin/compiler.jar", "--js", tempFile, "--js_output_file", sourceFile ];
				
				if (!InstallTool.verbose) {
					
					args.push ("--jscomp_off=uselessCode");
					
				}
				
				ProcessHelper.runCommand ("", "java", args);
				
			}
			
			FileSystem.deleteFile (tempFile);
			
		}
		
		if (target != "html5") {
			
			CordovaHelper.build (outputDirectory + "/bin", debug);
			
		}
		
	}
	
	
	override function clean ():Void {
		
		var targetPath = buildDirectory + "/html5";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	override function generateContext () {
		
		if (targetFlags.exists ("html5")) {
			
			compilerFlags.push ("-lib cordova");
			CordovaHelper.initialize (defines, targetFlags, target, NME);
			
		}
		
		super.generateContext ();
		
		outputDirectory = buildDirectory + "/html5/";
		
		if (target == "html5") {
			
			outputDirectory += "web";
			
		} else {
			
			outputDirectory += target;
			
		}
		
		outputFile = outputDirectory + "/bin/" + defines.get ("APP_FILE") + ".js";
		
		if (target != "html5") {
			
			outputFile = outputDirectory + "/bin/" + CordovaHelper.contentPath + defines.get ("APP_FILE") + ".js";
			
		}
		
		context.OUTPUT_DIR = outputDirectory;
		context.OUTPUT_FILE = outputFile;
		
		CordovaHelper.updateIcon (buildDirectory + "/html5/" + target, icons, assets, context);
		
	}
	
	
	private function generateFontData (font:Asset, destination:String):Void {
		
		var sourcePath = font.sourcePath;
		var targetPath = destination + font.targetPath;
		
		if (!FileSystem.exists (FileSystem.fullPath (sourcePath) + ".hash")) {
			
			ProcessHelper.runCommand (Path.directory (targetPath), "neko", [ templatePaths[0] + "html5/hxswfml.n", "ttf2hash", FileSystem.fullPath (sourcePath), "-glyphs", "32-255" ] );
			
		}
		
		context.HAXE_FLAGS += "\n-resource " + FileSystem.fullPath (sourcePath) + ".hash@NME_" + font.flatName;
		
	}
	
	
	override function run ():Void {
		
		if (target == "html5") {
			
			if (defines.exists ("APP_URL")) {
					
				ProcessHelper.openURL (defines.get ("APP_URL"));		
					
			} else {
				
				ProcessHelper.openFile (buildDirectory + "/html5/web/bin", "index.html");
				
			}
			
		} else {
			
			CordovaHelper.launch (buildDirectory + "/html5/" + target + "/bin", debug);
			
		}
		
	}
	
	
	override function update ():Void {
		
		var destination = outputDirectory + "/bin/";
		PathHelper.mkdir (destination);
		
		if (target != "html5") {
			
			CordovaHelper.create ("", destination, context);
			destination += CordovaHelper.contentPath;
			
		}
		
		for (asset in assets) {
			
			if (asset.type != Asset.TYPE_TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (destination + asset.targetPath));
				
				if (asset.type != Asset.TYPE_FONT) {
					
					// going to root directory now, but should it be a forced "assets" folder later?
					
					if (target == "html5") {
						
						FileHelper.copyIfNewer (asset.sourcePath, destination + asset.targetPath);
						
					} else {
						
						File.copy (asset.sourcePath, destination + asset.targetPath);
						
					}
					
				} else {
					
					generateFontData (asset, destination);
					
				}
				
			}
			
		}
		
		FileHelper.recursiveCopy (templatePaths[0] + "html5/template", destination, context);
		
		if (defines.exists ("APP_MAIN")) {
			
			FileHelper.recursiveCopy (templatePaths[0] + "haxe", outputDirectory + "/haxe", context);
			FileHelper.recursiveCopy (templatePaths[0] + "html5/haxe", outputDirectory + "/haxe", context);
			FileHelper.recursiveCopy (templatePaths[0] + "html5/hxml", outputDirectory + "/haxe", context);
			
		}
		
		for (asset in assets) {
						
			if (asset.type == Asset.TYPE_TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (destination + asset.targetPath));
				FileHelper.copyFile (asset.sourcePath, destination + asset.targetPath, context);
				
			}
			
		}
		
	}
	
	
}