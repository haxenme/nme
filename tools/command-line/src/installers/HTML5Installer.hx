package installers;


import data.Asset;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.Process;


/**
 * ...
 * @author Joshua Granick
 */

class HTML5Installer extends InstallerBase {
	
	
	private var outputDirectory:String;
	private var outputFile:String;
	
	
	override function build ():Void {
		
		var hxml:String = outputDirectory + "/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
		if (targetFlags.exists ("minify")) {
			
			if (defines.exists ("JAVA_HOME")) {
				
				Sys.putEnv ("JAVA_HOME", defines.get ("JAVA_HOME"));
				
			}
			
			var sourceFile = outputDirectory + "/bin/" + defines.get ("APP_FILE") + ".js";
			var tempFile = outputDirectory + "/bin/_" + defines.get ("APP_FILE") + ".js";
			
			FileSystem.rename (sourceFile, tempFile);
			
			if (targetFlags.exists ("yui")) {
				
				runCommand ("", "java", [ "-jar", NME + "/tools/command-line/bin/yuicompressor-2.4.7.jar", "-o", sourceFile, tempFile ]);
				
			} else {
				
				var args = [ "-jar", NME + "/tools/command-line/bin/compiler.jar", "--js", tempFile, "--js_output_file", sourceFile ];
				
				if (!InstallTool.verbose) {
					
					args.push ("--jscomp_off=uselessCode");
					
				}
				
				runCommand ("", "java", args);
				
			}
			
			FileSystem.deleteFile (tempFile);
			
		}
		
		if (targetFlags.exists ("html5")) {
			
			var ant:String = defines.get ("ANT_HOME");
			
			if (ant == null || ant == "") {
				
				ant = "ant";
				
			} else {
				
				ant += "/bin/ant";
				
			}
			
			if (target == "ios") {
				
				var platformName:String = "iphoneos";
		        
		        if (targetFlags.exists("simulator")) {
		            platformName = "iphonesimulator";
		        }
		        
		        var configuration:String = "Release";
		        
		        if (debug) {
		            configuration = "Debug";
		        }
					
		        var iphoneVersion:String = defines.get ("IPHONE_VER");
		        //var commands = [ "-configuration", configuration, "PLATFORM_NAME=" + platformName, "SDKROOT=" + platformName + iphoneVersion ];
		        var commands = [ "-configuration", configuration, "PLATFORM_NAME=" + platformName, "SDKROOT=" + platformName + iphoneVersion ];
					
		        if (targetFlags.exists("simulator")) {
		            commands.push ("-arch");
		            commands.push ("i386");
		        }
					
		        runCommand (outputDirectory + "/bin", "xcodebuild", commands);
		        
		        if (!targetFlags.exists ("simulator")) {
		            
		            var configuration:String = "Release";
					
		            if (debug) {
		                configuration = "Debug";
		            }
		            
		            var applicationPath:String = outputDirectory + "/bin/build/" + configuration + "-iphoneos/" + defines.get ("APP_FILE") + ".app";
		            
		           	runCommand ("", "codesign", [ "-s", "iPhone Developer", "--entitlements", outputDirectory + "/bin/" + defines.get("APP_FILE") + "/" + defines.get("APP_FILE") + "-Entitlements.plist", FileSystem.fullPath (applicationPath) ], true);
		            
		        }
				
			}
			
			//runCommand ("", "~/Development/PhoneGap/lib/" + target + "/bin/create", [ buildDirectory + "/html5/bin", defines.get ("APP_PACKAGE") ]);
			//runCommand (buildDirectory + "/html5/bin", ant, [ "
			
		}
		
	}
	
	
	override function clean ():Void {
		
		var targetPath = buildDirectory + "/html5";
		
		if (FileSystem.exists (targetPath)) {
			
			removeDirectory (targetPath);
			
		}
		
	}
	
	
	override function generateContext () {
		
		super.generateContext ();
		
		outputDirectory = buildDirectory + "/html5/";
		
		if (target == "html5") {
			
			outputDirectory += "web";
			
		} else {
			
			outputDirectory += target;
			
		}
		
		outputFile = outputDirectory + "/bin/" + defines.get ("APP_FILE") + ".js";
		
		if (target != "html5") {
			
			outputFile = outputDirectory + "/bin/www/" + defines.get ("APP_FILE") + ".js";
			
		}
		
		context.OUTPUT_DIR = outputDirectory;
		context.OUTPUT_FILE = outputFile;
		
	}
	
	
	private function generateFontData (font:Asset, destination:String):Void {
		
		var sourcePath = font.sourcePath;
		var targetPath = destination + font.targetPath;
		
		if (!FileSystem.exists (FileSystem.fullPath (sourcePath) + ".hash")) {
			
			runCommand (Path.directory (targetPath), "neko", [ templatePaths[0] + "html5/hxswfml.n", "ttf2hash", FileSystem.fullPath (sourcePath), "-glyphs", "32-255" ] );
			
		}
		
		context.HAXE_FLAGS += "\n-resource " + FileSystem.fullPath (sourcePath) + ".hash@NME_" + font.flatName;
		
	}
	
	
	private override function onCreate ():Void {	
		
		if (targetFlags.exists ("html5") && !defines.exists("IPHONE_VER")) {
			if (!defines.exists("DEVELOPER_DIR")) {
		        var proc = new Process("xcode-select", ["--print-path"]);
		        var developer_dir = proc.stdout.readLine();
		        proc.close();
		        defines.set("DEVELOPER_DIR", developer_dir);
		    }
			var dev_path = defines.get("DEVELOPER_DIR") + "/Platforms/iPhoneOS.platform/Developer/SDKs";
         	
			if (FileSystem.exists (dev_path)) {
				var best = "";
            	var files = FileSystem.readDirectory (dev_path);
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
	}
	
	
	override function run ():Void {
		
		var destination:String = buildDirectory + "/html5/bin";
		var dotSlash:String = "./";
		
		if (InstallTool.isWindows) {
			
			if (defines.exists ("DEV_URL"))
				runCommand (destination, defines.get("DEV_URL"), []);
			else
				runCommand (destination, ".\\index.html", []);
			
		} else if (InstallTool.isMac) {
			
			if (defines.exists ("DEV_URL"))
				runCommand (destination, "open", [ defines.get("DEV_URL") ]);
			else
				runCommand (destination, "open", [ "index.html" ]);
			
		} else {
			
			if (defines.exists ("DEV_URL"))
				runCommand (destination, "xdg-open", [ defines.get("DEV_URL") ]);
			else
				runCommand (destination, "xdg-open", [ "index.html" ]);
			
		}
		
	}
	
	
	override function update ():Void {
		
		var destination = outputDirectory + "/bin/";
		mkdir (destination);
		
		if (targetFlags.exists ("html5")) {
			
			runCommand ("", "~/Development/PhoneGap/lib/" + target + "/bin/create", [ destination, defines.get ("APP_PACKAGE"), defines.get ("APP_FILE") ]);
			
			destination += "www/";
			
		}
		
		for (asset in assets) {
			
			if (asset.type != Asset.TYPE_TEMPLATE) {
				
				mkdir (Path.directory (destination + asset.targetPath));
				
				if (asset.type != Asset.TYPE_FONT) {
					
					// going to root directory now, but should it be a forced "assets" folder later?
					
					copyIfNewer (asset.sourcePath, destination + asset.targetPath);
					
				} else {
					
					generateFontData (asset, destination);
					
				}
				
			}
			
		}
		
		recursiveCopy (templatePaths[0] + "html5/template", destination);
		recursiveCopy (templatePaths[0] + "haxe", outputDirectory + "/haxe");
		recursiveCopy (templatePaths[0] + "html5/haxe", outputDirectory + "/haxe");
		recursiveCopy (templatePaths[0] + "html5/hxml", outputDirectory + "/haxe");
		
		for (asset in assets) {
						
			if (asset.type == Asset.TYPE_TEMPLATE) {
				
				mkdir (Path.directory (destination + asset.targetPath));
				copyFile (asset.sourcePath, destination + asset.targetPath);
				
			}
			
		}
		
	}
	
	
}