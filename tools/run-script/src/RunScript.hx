import neko.FileSystem;
import neko.io.File;
import neko.io.Path;
import neko.io.Process;
import neko.Lib;
import neko.Sys;


class RunScript {
	
	
	private static var nmeDirectory:String;
	
	
	private static function build (targets:Array<String> = null):Void {
		
		if (targets == null) {
			
			targets = [ "tools" ];
			
			if (new EReg ("window", "i").match (Sys.systemName ())) {
				
				targets.push ("windows");
				
			} else if (new EReg ("linux", "i").match (Sys.systemName ())) {
				
				targets.push ("linux");
				
			} else if (new EReg ("mac", "i").match (Sys.systemName ())) {
				
				targets.push ("mac");
				
			}
			
		}
		
		for (target in targets) {
			
			if (target == "tools") {
				
				runCommand (nmeDirectory + "/tools/command-line", "haxe", [ "CommandLine.hxml" ]);
				
			} else if (target == "clean") {
				
				var directories = [ nmeDirectory + "/project/obj" ];
				var files = [ nmeDirectory + "/project/all_objs", nmeDirectory + "/project/vc100.pdb" ];
				
				for (directory in directories) {
					
					removeDirectory (directory);
					
				}
				
				for (file in files) {
					
					if (FileSystem.exists (file)) {
						
						FileSystem.deleteFile (file);
						
					}
					
				}
				
			} else {
				
				buildLibrary (target);
				
			}
			
		}
		
	}
	
	
	static private function buildLibrary (target:String):Void {
		
		if (!FileSystem.exists (nmeDirectory + "/../sdl-static")) {
			
			error ("You must have \"sdl-static\" checked out next to NME to build libraries");
			return;
			
		}
		
		var projectDirectory = nmeDirectory + "/project";
		
		// The -Ddebug directive creates a debug build of the library, but the -Dfulldebug directive
		// will create a debug library using the ".debug" suffix on the file name, so both the release
		// and debug libraries can exist in the same directory
		
		switch (target) {
			
			case "android":
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dandroid" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dandroid", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dandroid", "-DHXCPP_ARMV7", "-DHXCPP_ARM7" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dandroid", "-DHXCPP_ARMV7", "-DHXCPP_ARM7", "-Dfulldebug" ]);
			
			case "blackberry":
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dblackberry" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dblackberry", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dblackberry", "-Dsimulator" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dblackberry", "-Dsimulator", "-Dfulldebug" ]);
			
			case "ios":
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphoneos" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphoneos", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphoneos", "-DHXCPP_ARMV7" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphoneos", "-DHXCPP_ARMV7", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphonesim" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphonesim", "-Dfulldebug" ]);
			
			case "linux":
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-DHXCPP_M64" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-DHXCPP_M64", "-Dfulldebug" ]);
			
			case "mac":
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dfulldebug" ]);
			
			case "webos":
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dwebos" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dwebos", "-Dfulldebug" ]);
			
			case "windows":
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dfulldebug" ]);
			
		}
		
	}
	
	
	public static function error (message:String = "", e:Dynamic = null):Void {
		
		if (message != "") {
			
			if (nme_error_output == null) {
				
				try {
					
					nme_error_output = Lib.load ("nme", "nme_error_output", 1);
					
				} catch (e:Dynamic) {
					
					nme_error_output = Lib.println;
					
				}
				
			}
			
			try {
				
				nme_error_output ("Error: " + message + "\n");
				
			} catch (e:Dynamic) {}
			
		}
		
		if (e != null) {
			
			Lib.rethrow (e);
			
		}
		
		Sys.exit (1);
		
	}
	
	
	public static function getHaxelib (library:String):String {
		
		var proc = new Process ("haxelib", ["path", library ]);
		var result = "";
		
		try {
			
			while (true) {
				
				var line = proc.stdout.readLine ();
				
				if (line.substr (0,1) != "-") {
					
					result = line;
					break;
					
				}
				
			}
			
		} catch (e:Dynamic) { };
		
		proc.close();
		
		//Lib.println ("Found " + library + " at " + result );
		//trace("Found " + haxelib + " at " + srcDir );
		
		if (result == "") {
			
			throw ("Could not find haxelib path  " + library + " - perhaps you need to install it?");
			
		}
		
		return result;
		
	}
	
	
	private static function removeDirectory (directory:String):Void {
		
		if (FileSystem.exists (directory)) {
			
			for (file in FileSystem.readDirectory (directory)) {
				
				var path = directory + "/" + file;
				
				if (FileSystem.isDirectory (path)) {
					
					removeDirectory (path);
					
				} else {
					
					FileSystem.deleteFile (path);
					
				}
				
			}
			
			FileSystem.deleteDirectory (directory);
			
		}
		
	}
	

	public static function runCommand (path:String, command:String, args:Array<String>) {
		
		var oldPath:String = "";
		
		if (path != "") {
			
			//Lib.println ("cd " + path);
			
			oldPath = Sys.getCwd ();
			Sys.setCwd (path);
			
		}
		
		//Lib.println (command + (args==null ? "": " " + args.join(" ")) );
		
		var result:Dynamic = Sys.command (command, args);
		
		if (result == 0)
			//print("Ok.");
			
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
		if (result != 0) {
			
			//throw ("Error running: " + command + " " + args.join (" ") + " [" + path + "]");
			
		}
		
	}
	
	
	public static function main () {
		
		nmeDirectory = getHaxelib ("nme");
		
		if (!FileSystem.exists (nmeDirectory + "/tools/command-line/command-line.n")) {
			
			build ();
			
		}
		
		var args:Array <String> = Sys.args ();
		
		if (args[0] == "rebuild" && nmeDirectory.indexOf ("C:\\Motion-Twin") == -1 && nmeDirectory.indexOf ("/usr/lib/haxe/lib") == -1) {
			
			var targets:Array <String> = null;
			
			if (args.length > 2) {
				
				build (args[1].split (","));
				
			} else {
				
				build ();
				
			}
			
		} else {
			
			args.unshift ("tools/command-line/command-line.n");
			runCommand (nmeDirectory, "neko", args);
			
		}
		
	}
	
	
	private static var nme_error_output;
	
	
}