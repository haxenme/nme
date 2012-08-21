import neko.zip.Writer;
import haxe.io.Eof;
import haxe.Http;
import haxe.io.Path;
import neko.Lib;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;


class RunScript {
	
	
	private static var isLinux:Bool;
	private static var isMac:Bool;
	private static var isWindows:Bool;
	private static var nmeDirectory:String;
	private static var nmeFilters:Array <String> = [ "obj", ".git", ".gitignore", ".svn", ".DS_Store", "all_objs", "Export", "tools/documentation/bin" ];
	
	
	private static function build (targets:Array<String> = null):Void {
		
		if (targets == null) {
			
			targets = [ "tools" ];
			
			if (isWindows) {
				
				targets.push ("windows");
				
			} else if (isLinux) {
				
				targets.push ("linux");
				
			} else if (isMac) {
				
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
				
				if (target == "all") {
					
					if (isWindows) {
						
						buildLibrary ("windows");
						buildLibrary ("android");
						buildLibrary ("blackberry");
						buildLibrary ("webos");
						
					} else if (isLinux) {
						
						buildLibrary ("linux");
						buildLibrary ("android");
						buildLibrary ("blackberry");
						buildLibrary ("webos");
						
					} else if (isMac) {
						
						buildLibrary ("mac");
						buildLibrary ("ios");
						buildLibrary ("android");
						buildLibrary ("blackberry");
						buildLibrary ("webos");
						
					}
					
					buildDocumentation ();
					
				} else if (target == "documentation") {
					
					buildDocumentation ();
					
				} else {
					
					buildLibrary (target);
					
				}
				
			}
			
		}
		
	}
	
	
	static private function buildDocumentation ():Void {
		
		runCommand (nmeDirectory + "/tools/documentation", "haxe", [ "compile.hxml" ]);
		
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
				
				mkdir (nmeDirectory + "/ndll/Android");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dandroid" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dandroid", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dandroid", "-DHXCPP_ARMV7", "-DHXCPP_ARM7" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dandroid", "-DHXCPP_ARMV7", "-DHXCPP_ARM7", "-Dfulldebug" ]);
			
			case "blackberry":
				
				mkdir (nmeDirectory + "/ndll/BlackBerry");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dblackberry" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dblackberry", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dblackberry", "-Dsimulator" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dblackberry", "-Dsimulator", "-Dfulldebug" ]);
			
			case "ios":
				
				mkdir (nmeDirectory + "/ndll/iPhone");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphoneos" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphoneos", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphoneos", "-DHXCPP_ARMV7" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphoneos", "-DHXCPP_ARMV7", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphonesim" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphonesim", "-Dfulldebug" ]);
			
			case "linux":
				
				mkdir (nmeDirectory + "/ndll/Linux");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dfulldebug" ]);
				
				if (isRunning64 ()) {
					
					mkdir (nmeDirectory + "/ndll/Linux64");
					
					runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-DHXCPP_M64" ]);
					runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-DHXCPP_M64", "-Dfulldebug" ]);
					
				}
			
			case "mac":
				
				mkdir (nmeDirectory + "/ndll/Mac");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dfulldebug" ]);
			
			case "webos":
				
				mkdir (nmeDirectory + "/ndll/webOS");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dwebos" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dwebos", "-Dfulldebug" ]);
			
			case "windows":
				
				if (Sys.environment ().exists ("VS110COMNTOOLS")) {
					
					Lib.println ("Warning: Visual Studio 2012 is not supported. Trying Visual Studio 2010...");
					
					Sys.putEnv ("VS110COMNTOOLS", Sys.getEnv ("VS100COMNTOOLS"));
					
				}
				
				mkdir (nmeDirectory + "/ndll/Windows");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dfulldebug" ]);
			
		}
		
	}
	
	
	private static function downloadFile (remotePath:String, localPath:String) {
		
		var out = File.write (localPath, true);
		var progress = new Progress (out);
		var h = new Http (remotePath);
		
		h.onError = function (e) {
			progress.close();
			FileSystem.deleteFile (localPath);
			throw e;
		};
		
		h.customRequest (false, progress);
		
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
	
	
	private static function getRevision ():String {
		
		var result = "r0";
		
		if (FileSystem.exists (nmeDirectory + "/.git")) {
			
			var cacheCwd = Sys.getCwd ();
			Sys.setCwd (nmeDirectory);
			
			var proc = new Process ("git", [ "svn", "log", "--oneline", "-1" ]);
			
			try {
				
				result = proc.stdout.readLine ();
				result = result.substr (0, result.indexOf (" |"));
				
			} catch (e:Dynamic) { };
			
			proc.close();
			Sys.setCwd (cacheCwd);
			
		} else if (FileSystem.exists (nmeDirectory + "/.svn")) {
			
			var cacheCwd = Sys.getCwd ();
			Sys.setCwd (nmeDirectory);
			
			var proc = new Process ("git", [ "svn", "log", "--oneline", "-1" ]);
			
			try {
				
				while (true) {
					
					result = proc.stdout.readLine ();
					
					var checkString = "Revision: ";
					var index = result.indexOf (checkString);
					
					if (index > -1) {
						
						result = result.substr (checkString.length);
						break;
						
					}
					
				}
				
			} catch (e:Dynamic) { };
			
			proc.close();
			Sys.setCwd (cacheCwd);
			
		}
		
		return result;
		
	}
	
	
	private static function getVersion (library:String = "nme", haxelibFormat:Bool = false):String {
		
		var libraryPath = nmeDirectory;
		
		if (library != "nme") {
			
			libraryPath = getHaxelib (library);
			
		}
		
		for (element in Xml.parse (File.getContent (libraryPath + "/haxelib.xml")).firstElement ().elements ()) {
			
			if (element.nodeName == "version") {
				
				if (haxelibFormat) {
					
					return StringTools.replace (element.get ("name"), ".", ",");
					
				} else {
					
					return element.get ("name");
					
				}
				
			}
			
		}
		
		return "";
		
	}
	
	
	public static function isRunning64 ():Bool {
		
		if (Sys.systemName () == "Linux") {
			
			var proc = new Process ("uname", [ "-m" ]);
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
			
			return result == "x86_64";
			
		} else {
			
			return false;
			
		}
		
	}
	
	
	public static function mkdir (directory:String):Void {
		
		directory = StringTools.replace (directory, "\\", "/");
		var total = "";
		
		if (directory.substr (0, 1) == "/") {
			
			total = "/";
			
		}
		
		var parts = directory.split("/");
		var oldPath = "";
		
		if (parts.length > 0 && parts[0].indexOf (":") > -1) {
			
			oldPath = Sys.getCwd ();
			Sys.setCwd (parts[0] + "\\");
			parts.shift ();
			
		}
		
		for (part in parts) {
			
			if (part != "." && part != "") {
				
				if (total != "") {
					
					total += "/";
					
				}
				
				total += part;
				
				if (!FileSystem.exists (total)) {
					
					//print("mkdir " + total);
					
					FileSystem.createDirectory (total);
					
				}
				
			}
			
		}
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
	}
	
	
	private static function param (name:String, ?passwd:Bool):String {
		
		Sys.print (name + " : ");
		
		if (passwd) {
			var s = new StringBuf ();
			var c;
			while ((c = Sys.getChar(false)) != 13)
				s.addChar (c);
			Sys.print ("");
			return s.toString ();
		}
		
		try {
			
			return Sys.stdin ().readLine ();
			
		} catch (e:Eof) {
			
			return "";
			
		}
		
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
	

	public static function runCommand (path:String, command:String, args:Array<String>):Int {
		
		var oldPath:String = "";
		
		if (path != "") {
			
			//Lib.println ("cd " + path);
			
			oldPath = Sys.getCwd ();
			Sys.setCwd (path);
			
		}
		
		//Lib.println (command + (args==null ? "": " " + args.join(" ")) );
		
		var result:Dynamic = Sys.command (command, args);
		
		//if (result == 0)
			//print("Ok.");
			
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
		return result;
		
		//if (result != 0) {
			
			//throw ("Error running: " + command + " " + args.join (" ") + " [" + path + "]");
			
		//}
		
	}
	
	
	public static function main () {
		
		nmeDirectory = getHaxelib ("nme");
		
		if (new EReg ("window", "i").match (Sys.systemName ())) {
			
			isLinux = false;
			isMac = false;
			isWindows = true;
			
		} else if (new EReg ("linux", "i").match (Sys.systemName ())) {
			
			isLinux = true;
			isMac = false;
			isWindows = false;
			
		} else if (new EReg ("mac", "i").match (Sys.systemName ())) {
			
			isLinux = false;
			isMac = true;
			isWindows = false;
			
		}
		
		var args:Array <String> = Sys.args ();
		var command = args[0];
		
		if (command == "rebuild" || command == "release") {
			
			if (nmeDirectory.indexOf ("C:\\Motion-Twin") != -1 || nmeDirectory.indexOf ("/usr/lib/haxe/lib") != -1) {
				
				Sys.println ("This command can only be run from a development build of NME");
				return;
				
			}
			
			var targets:Array <String> = null;
			
			if (args.length > 2) {
				
				targets = args[1].split (",");
				
			}
			
			switch (command) {
				
				case "rebuild":
					
					build (targets);
				
				case "release":
					
					release (targets);
					
			}
			
		} else {
			
			if (!FileSystem.exists (nmeDirectory + "/tools/command-line/command-line.n")) {
				
				build ();
				
			}
			
			args.unshift ("tools/command-line/command-line.n");
			Sys.exit (runCommand (nmeDirectory, "neko", args));
			
		}
		
	}
	
	
	public static function recursiveCopy (source:String, destination:String, ignore:Array <String>) {
		
		mkdir (destination);
		
		var files = FileSystem.readDirectory (source);
		
		for (file in files) {
			
			var ignoreFile = false;
			
			for (ignoreName in ignore) {
				
				if (file == ignoreName || StringTools.endsWith (source + "/" + file, "/" + ignoreName)) {
					
					ignoreFile = true;
					
				}
				
			}
			
			if (!ignoreFile) {
				
				var itemDestination:String = destination + "/" + file;
				var itemSource:String = source + "/" + file;
				
				if (FileSystem.isDirectory (itemSource)) {
					
					recursiveCopy (itemSource, itemDestination, ignore);
					
				} else {
					
					File.copy (itemSource, itemDestination);
					
				}
				
			}
			
		}
		
	}
	
	
	private static function release (targets:Array<String> = null):Void {
		
		if (targets == null) {
			
			targets = [ "zip" ];
			
		}
		
		for (target in targets) {
			
			switch (target) {
				
				case "upload":
					
					var user = param ("FTP username");
					var password = param ("FTP password", true);
					
					if (isWindows) {
						
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Windows/nme.ndll" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Windows/nme-debug.ndll" ]);
						
					} else if (isLinux) {
						
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Linux/nme.ndll" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Linux/nme-debug.ndll" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Linux64/nme.ndll" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Linux64/nme-debug.ndll" ]);
						
					} else if (isMac) {
						
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Mac/nme.ndll" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Mac/nme-debug.ndll" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "iPhone/libnme.iphoneos.a" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "iPhone/libnme.iphoneos-v7.a" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "iPhone/libnme.iphonesim.a" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "iPhone/libnme-debug.iphoneos.a" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "iPhone/libnme-debug.iphoneos-v7.a" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "iPhone/libnme-debug.iphonesim.a" ]);
						
					}
			
				case "download":
					
					if (!isWindows) {
					
						downloadFile ("http://www.haxenme.org/builds/ndll/Windows/nme.ndll", nmeDirectory + "/ndll/Windows/nme.ndll");
						downloadFile ("http://www.haxenme.org/builds/ndll/Windows/nme-debug.ndll", nmeDirectory + "/ndll/Windows/nme-debug.ndll");
					
					}
					
					if (!isLinux) {
						
						downloadFile ("http://www.haxenme.org/builds/ndll/Linux/nme.ndll", nmeDirectory + "/ndll/Linux/nme.ndll");
						downloadFile ("http://www.haxenme.org/builds/ndll/Linux/nme-debug.ndll", nmeDirectory + "/ndll/Linux/nme-debug.ndll");
						downloadFile ("http://www.haxenme.org/builds/ndll/Linux64/nme.ndll", nmeDirectory + "/ndll/Linux64/nme.ndll");
						downloadFile ("http://www.haxenme.org/builds/ndll/Linux64/nme-debug.ndll", nmeDirectory + "/ndll/Linux64/nme-debug.ndll");
						
					}
					
					if (!isMac) {
						
						downloadFile ("http://www.haxenme.org/builds/ndll/Mac/nme.ndll", nmeDirectory + "/ndll/Mac/nme.ndll");
						downloadFile ("http://www.haxenme.org/builds/ndll/Mac/nme-debug.ndll", nmeDirectory + "/ndll/Mac/nme-debug.ndll");
						downloadFile ("http://www.haxenme.org/builds/ndll/iPhone/libnme.iphoneos.a", nmeDirectory + "/ndll/iPhone/libnme.iphoneos.a");
						downloadFile ("http://www.haxenme.org/builds/ndll/iPhone/libnme.iphoneos-v7.a", nmeDirectory + "/ndll/iPhone/libnme.iphoneos-v7.a");
						downloadFile ("http://www.haxenme.org/builds/ndll/iPhone/libnme.iphonesim.a", nmeDirectory + "/ndll/iPhone/libnme.iphonesim.a");
						downloadFile ("http://www.haxenme.org/builds/ndll/iPhone/libnme-debug.iphoneos.a", nmeDirectory + "/ndll/iPhone/libnme-debug.iphoneos.a");
						downloadFile ("http://www.haxenme.org/builds/ndll/iPhone/libnme-debug.iphoneos-v7.a", nmeDirectory + "/ndll/iPhone/libnme-debug.iphoneos-v7.a");
						downloadFile ("http://www.haxenme.org/builds/ndll/iPhone/libnme-debug.iphonesim.a", nmeDirectory + "/ndll/iPhone/libnme-debug.iphonesim.a");
						
					}
					
				case "zip":
					
					var tempPath = "../nme-release-zip";
					var targetPath = "../nme-" + getVersion () + "-" + getRevision () + ".zip";
					
					recursiveCopy (nmeDirectory, nmeDirectory + tempPath + "/nme", nmeFilters);
					
					if (FileSystem.exists (nmeDirectory + targetPath)) {
						
						FileSystem.deleteFile (nmeDirectory + targetPath);
						
					}
					
					if (!isWindows) {
						
						runCommand (nmeDirectory + tempPath, "zip", [ "-r", targetPath, "*" ]);
						
					}
					
					removeDirectory (nmeDirectory + tempPath);
				
				case "installer":
					
					var hxcppPath = getHaxelib ("hxcpp");
					var nmePath = getHaxelib ("nme");
					var swfPath = getHaxelib ("swf");
					var actuatePath = getHaxelib ("actuate");
					var svgPath = getHaxelib ("svg");
					
					var hxcppVersion = getVersion ("hxcpp", true);
					var nmeVersion = getVersion ("nme", true);
					var swfVersion = getVersion ("swf", true);
					var actuateVersion = getVersion ("actuate", true);
					var svgVersion = getVersion ("svg", true);
					
					if (isMac) {
						
						var tempPath = "../nme-release-installer";
						var targetPath = "../NME-" + getVersion () + "-Mac-" + getRevision () + ".mpkg";
						
						var haxePath = "/usr/lib/haxe";
						var nekoPath = "/usr/lib/neko";
						
						removeDirectory (nmeDirectory + tempPath);
						recursiveCopy (nmeDirectory + "/tools/installer/mac", nmeDirectory + tempPath, [ ]);
						
						recursiveCopy ("/usr/lib/haxe", nmeDirectory + tempPath + "/resources/haxe/usr/lib/haxe", [ "lib" ]);
						recursiveCopy ("/usr/lib/neko", nmeDirectory + tempPath + "/resources/haxe/usr/lib/neko", []);
						
						recursiveCopy (hxcppPath, nmeDirectory + tempPath + "/resources/hxcpp/usr/lib/haxe/lib/hxcpp/" + hxcppVersion, [ "obj", "all_objs", ".git", ".svn" ]);
						recursiveCopy (nmePath, nmeDirectory + tempPath + "/resources/nme/usr/lib/haxe/lib/nme/" + nmeVersion, nmeFilters);
						recursiveCopy (swfPath, nmeDirectory + tempPath + "/resources/swf/usr/lib/haxe/lib/swf/" + swfVersion, [ ".git", ".svn" ]);
						recursiveCopy (actuatePath, nmeDirectory + tempPath + "/resources/actuate/usr/lib/haxe/lib/actuate/" + actuateVersion, [ ".git", ".svn" ]);
						recursiveCopy (svgPath, nmeDirectory + tempPath + "/resources/svg/usr/lib/haxe/lib/svg/" + svgVersion, [ ".git", ".svn" ]);
						
						File.saveContent (nmeDirectory + tempPath + "/resources/hxcpp/usr/lib/haxe/lib/hxcpp/.current", getVersion ("hxcpp"));
						File.saveContent (nmeDirectory + tempPath + "/resources/nme/usr/lib/haxe/lib/nme/.current", getVersion ("nme"));
						File.saveContent (nmeDirectory + tempPath + "/resources/swf/usr/lib/haxe/lib/swf/.current", getVersion ("swf"));
						File.saveContent (nmeDirectory + tempPath + "/resources/actuate/usr/lib/haxe/lib/actuate/.current", getVersion ("actuate"));
						File.saveContent (nmeDirectory + tempPath + "/resources/svg/usr/lib/haxe/lib/svg/.current", getVersion ("svg"));
						
						runCommand (nmeDirectory + tempPath, "chmod", [ "+x", "./prep.sh" ]);
						runCommand (nmeDirectory + tempPath, "./prep.sh", [ ]);
						
						runCommand (nmeDirectory + tempPath, "/Applications/PackageMaker.app/Contents/MacOS/PackageMaker", [ nmeDirectory + tempPath + "/Installer.pmdoc" ]);
						removeDirectory (nmeDirectory + tempPath);
						
					}
				
			}
			
		}
		
	}
	
	
	private static var nme_error_output;
	
	
}


class Progress extends haxe.io.Output {

	var o : haxe.io.Output;
	var cur : Int;
	var max : Int;
	var start : Float;

	public function new(o) {
		this.o = o;
		cur = 0;
		start = haxe.Timer.stamp();
	}

	function bytes(n) {
		cur += n;
		if( max == null )
			Lib.print(cur+" bytes\r");
		else
			Lib.print(cur+"/"+max+" ("+Std.int((cur*100.0)/max)+"%)\r");
	}

	public override function writeByte(c) {
		o.writeByte(c);
		bytes(1);
	}

	public override function writeBytes(s,p,l) {
		var r = o.writeBytes(s,p,l);
		bytes(r);
		return r;
	}

	public override function close() {
		super.close();
		o.close();
		var time = haxe.Timer.stamp() - start;
		var speed = (cur / time) / 1024;
		time = Std.int(time * 10) / 10;
		speed = Std.int(speed * 10) / 10;
		Lib.print("Download complete : " + cur + " bytes in " + time + "s (" + speed + "KB/s)\n");
	}

	public override function prepare(m) {
		max = m;
	}

}
