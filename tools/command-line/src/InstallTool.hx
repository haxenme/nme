import documentation.DocumentationGenerator;
import haxe.io.Eof;
import haxe.io.Path;
import helpers.FileHelper;
import helpers.PathHelper;
import installers.AndroidInstaller;
import installers.BlackBerryInstaller;
import installers.CPPInstaller;
import installers.FlashInstaller;
import installers.HTML5Installer;
import installers.InstallerBase;
import installers.IOSInstaller;
import installers.NekoInstaller;
import installers.WebOSInstaller;
import generate.GenerateJavaExterns;
import neko.Lib;
import nme.Loader;
import setup.PlatformSetup;
import sys.io.File;
import sys.FileSystem;


class InstallTool {
	
	
	public static var isMac = false;
	public static var isLinux = false;
	public static var isWindows = false;
	public static var nme:String = "";
	public static var traceEnabled:Bool = true;
	public static var verbose = false;
	public static var version = "3.4.1";
	
	
	static public function create (nme:String, command:String, defines:Hash <String>, userDefines:Hash <String>, includePaths:Array <String>, projectFile:String, target:String, targetFlags:Hash <String>, debug:Bool, args:Array<String>) {
		
		var installer:InstallerBase = null;
		
		if (target == "windows" || target == "mac" || target == "linux") {
			
			if (targetFlags.exists ("neko") || (!defines.exists (target) && !targetFlags.exists ("cpp"))) {
				
				targetFlags.set (target, "");
				target = "neko";
				
			} else {
				
				target = "cpp";
				
			}
			
		}
		
		switch (target) {
			
			case "iphoneos", "iphonesim", "iphone":
				
				target = "ios";
			
		}
		
		if (command == "document") {
			
			installer = new DocumentationGenerator ();
			
		} else if (targetFlags.exists ("air")) {
			
			installer = new FlashInstaller ();
		
		} else if (targetFlags.exists ("html5")) {
			
			installer = new HTML5Installer ();
			
		} else {
			
			switch (target) {
				
				case "android":
					
					installer = new AndroidInstaller ();
				
				case "cpp":
					
					installer = new CPPInstaller ();
				
				case "iphoneos", "iphonesim", "iphone", "ios":
					
					installer = new IOSInstaller ();
				
				case "webos":
					
					installer = new WebOSInstaller ();
				
				case "flash":
					
					installer = new FlashInstaller ();
				
				case "neko":
					
					installer = new NekoInstaller ();
				
				case "html5":
					
					installer = new HTML5Installer ();
				
				case "blackberry":
					
					installer = new BlackBerryInstaller ();
				
				default:
					
					error ("'" + target + "' is not a valid target");
					return;
				
			}
			
		}
		
		installer.create (nme, command, defines, userDefines, includePaths, projectFile, target, targetFlags, debug, args);
		
	}
	
	
	private static function argumentError (message:String):Void {
		
		error (message);
		//Lib.println (error);
		/*Lib.println ("-------------------------------");
		Lib.println ("Usage :  haxelib run nme [-v] COMMAND ...");
		Lib.println (" COMMAND : copy-if-newer source destination");
		Lib.println (" COMMAND : (update|document) build.nmml [-DFLAG -Dname=val... ]");
		Lib.println (" COMMAND : (build|update|run|rerun|test) [-debug] build.nmml target");
		Lib.println (" COMMAND : (trace|uninstall) build.nmml target");*/
		
	}
	
	
	public static function error (message:String = "", e:Dynamic = null):Void {
		
		if (message != "") {
			
			try {
				
				nme_error_output ("Error: " + message + "\n");
				
			} catch (e:Dynamic) {}
			
		}
		
		if (InstallTool.verbose && e != null) {
			
			Lib.rethrow (e);
			
		}
		
		Sys.exit (1);
		
	}
	
	
	public static function getNeko ():String {
		
		var path:String = Sys.getEnv ("NEKO_INSTPATH");
		
		if (path == null || path == "") {
			
			path = Sys.getEnv ("NEKO_INSTALL_PATH");
			
		}
		
		if (path == null || path == "") {
			
			path = Sys.getEnv ("NEKOPATH");
			
		}
		
		if (path == null || path == "") {
			
			if (Sys.systemName () == "windows") {
				
				path = "C:/Motion-Twin/neko";
				
			} else {
				
				path = "/usr/lib/neko";
				
			}
			
		}
		
		return path + "/";
		
	}
	
	
	private static function getVersion ():String {
		
		for (element in Xml.parse (File.getContent (nme + "/haxelib.xml")).firstElement ().elements ()) {
			
			if (element.nodeName == "version") {
				
				return element.get ("name");
				
			}
			
		}
		
		return "";
		
	}
	
	
	public static function print (message:String):Void {
		
		if (verbose) {
			
			Lib.println(message);
			
		}
		
	}
	
	
	#if haxe_210
	
	public static function __init__ () {
		
		// Library search path fix
		
		var path = Utils.getHaxelib ("nme") + "ndll/";
		
		if (new EReg ("window", "i").match (Sys.systemName ())) {
			
			untyped $loader.path = $array(path + "Windows/", $loader.path);
			
		} else if (new EReg ("mac", "i").match (Sys.systemName ())) {
			
			untyped $loader.path = $array(path + "Mac/", $loader.path);
			
		} else if (new EReg ("linux", "i").match (Sys.systemName ())) {
			
			if (Lib.load ("std", "sys_is64", 0) ()) {
				
				untyped $loader.path = $array(path + "Linux64/", $loader.path);
				
			} else {
				
				untyped $loader.path = $array(path + "Linux/", $loader.path);
				
			}
			
		}
		
		//Sys.println (untyped $loader.path);
		
	}
	
	#end
	
	
	public static function main () {
		
		var command:String = "";
		var debug:Bool = false;
		var defines = new Hash <String> ();
		var userDefines = new Hash <String> ();
		var includePaths = new Array <String> ();
		var targetFlags = new Hash <String> ();
		
		includePaths.push (".");
		
		var args:Array <String> = Sys.args ();
		
		if (args.length > 0) {
			
			// When called from haxelib, the last argument is the calling directory. The path to nme is set as the current working directory 
			
			var lastArgument:String = new Path (args[args.length - 1]).toString ();
			
			if (((StringTools.endsWith (lastArgument, "/") && lastArgument != "/") || StringTools.endsWith (lastArgument, "\\")) && !StringTools.endsWith (lastArgument, ":\\")) {
				
				lastArgument = lastArgument.substr (0, lastArgument.length - 1);
				
			}
			
			if (FileSystem.exists (lastArgument) && FileSystem.isDirectory (lastArgument)) {
				
				nme = Sys.getCwd ();
				var last = nme.substr(-1,1);
				if (last=="/" || last=="\\")
				nme = nme.substr(0,-1);
				Sys.setCwd (lastArgument);
				
				defines.set ("NME", nme);
				args.pop ();
				
			}
			
		}
		
		if (new EReg ("window", "i").match (Sys.systemName ())) {
			
			defines.set ("windows", "1");
			defines.set ("NME_HOST", "windows");
			isWindows = true;
			
		} else if (new EReg ("linux", "i").match (Sys.systemName ())) {
			
			defines.set ("linux", "1");
			defines.set ("NME_HOST", "linux");
			isLinux = true;
			
		} else if (new EReg ("mac", "i").match (Sys.systemName ())) {
			
			defines.set ("mac", "1");
			defines.set ("macos", "1");
			defines.set ("NME_HOST", "darwin-x86");
			isMac = true;
			
		}
		
		version = getVersion ();
		
		var words:Array <String> = new Array <String> ();
		var passArgs:Array <String> = new Array <String> ();
		var pushArgs = false;
		
		for (arg in args) {
			
			var equals:Int = arg.indexOf ("=");
			
			if (pushArgs) {
				
				passArgs.push(arg);
				
			} else if (equals > 0) {
				
				if (arg.substr (0, 2) == "-D") {
					
					userDefines.set (arg.substr (2, equals - 2), arg.substr (equals + 1));
					
				} else {
					
					userDefines.set (arg.substr (0, equals), arg.substr (equals + 1));
					
				}
				
			} else if (arg.substr(0,4) == "-arm") {
				
				defines.set ("ARM" + arg.substr(4), "1");
				
			} else if (arg == "-64") {
				
				defines.set ("NME_64", "1");
				
			} else if (arg.substr (0, 2) == "-D") {
				
				userDefines.set (arg.substr (2), "");
				
			} else if (arg.substr (0, 2) == "-l") {
				
				includePaths.push (arg.substr (2));
				
			} else if (arg == "-v" || arg == "-verbose") {
				
				verbose = true;
				
			} else if (arg == "-args") {
				
				pushArgs = true;
				
			} else if (arg == "-notrace") {
				
				traceEnabled = false;
				
			} else if (arg == "-debug") {
				
				debug = true;
				defines.set ("debug", "");
				
			} else if (command.length == 0) {
				
				command = arg;
			
			} else if (arg.substr (0, 1) == "-") {
				
				targetFlags.set (arg.substr (1), "");
				
			} else {
				
				words.push (arg);
				
			}
			
		}
		
		if (userDefines.exists ("debug")) {
			
			debug = true;
			defines.set ("debug", "");
			
		}
		
		if (Sys.environment ().exists ("HOME")) {
			
			includePaths.push (Sys.getEnv ("HOME"));
			
		}
		
		if (Sys.environment ().exists ("USERPROFILE")) {
			
			includePaths.push (Sys.getEnv ("USERPROFILE"));
			
		}
		
		includePaths.push (nme + "/tools/command-line");
		
		var validCommands:Array <String> = [ "setup", "help", "copy-if-newer", "run", "rerun", "update", "test", "build", "clean", "installer", "uninstall", "trace", "document", "generate", "display", "new"  ];
		
		if (!Lambda.exists (validCommands, function (c) return command == c)) {
			
			if (command != "") {
				
				argumentError ("'" + command + "' is not a valid command");
				return;
				
			}
			
		}
		
		if (command == "") {
			
			Lib.println ("NME Command-Line Tools (" + version + ")");
			Lib.println ("Use \"nme setup\" to configure NME or \"nme help\" for more commands");
			
		} else if (command == "help") {
			
			Lib.println ("NME Command-Line Tools (" + version + ")");
			Lib.println ("");
			Lib.println (" Usage : nme setup (target)");
			Lib.println (" Usage : nme help");
			Lib.println (" Usage : nme [clean|update|build|run|test|display] <project> (target) [options]");
			Lib.println (" Usage : nme document <project> (target)");
			Lib.println (" Usage : nme generate <args> [options]");
			Lib.println (" Usage : nme new file.nmml name1=value1 name2=value2 ...");
			Lib.println ("");
			Lib.println (" Commands : ");
			Lib.println ("");
			Lib.println ("  setup : Setup NME or a specific target");
			Lib.println ("  help : Show this information");
			Lib.println ("  clean : Remove the target build directory if it exists");
			Lib.println ("  update : Copy assets for the specified project/target");
			Lib.println ("  build : Compile and package for the specified project/target");
			Lib.println ("  run : Install and run for the specified project/target");
			Lib.println ("  test : Update, build and run in one command");
			Lib.println ("  display : Display information for the specified project/target");
			Lib.println ("  document : Generate documentation using haxedoc");
			Lib.println ("  generate : Tools to help create source code automatically");
			Lib.println ("");
			Lib.println (" Targets : ");
			Lib.println ("");
			Lib.println ("  android : Create Google Android applications");
			Lib.println ("  blackberry : Create BlackBerry applications");
			Lib.println ("  cpp : Create application for the system you are compiling on");
			Lib.println ("  flash : Create SWF applications for Adobe Flash Player");
			Lib.println ("  html5 : Create HTML5 canvas applications");
			Lib.println ("  ios : Create Apple iOS applications");
			Lib.println ("  linux : Create Linux applications");
			Lib.println ("  mac : Create Apple Mac OS X applications");
			Lib.println ("  webos : Create HP webOS applications");
			Lib.println ("  windows : Create Microsoft Windows applications");
			Lib.println ("");
			Lib.println (" Options : ");
			Lib.println ("");
			Lib.println ("  -debug : Use debug configuration instead of release");
			Lib.println ("  -verbose : Print additional information (when available)");
			Lib.println ("  -clean : Add a \"clean\" action before running the current command");
			Lib.println ("  -xml : Generate XML type information, can be used with \"document\"");
			Lib.println ("  [windows|mac|linux] -neko : Build with Neko instead of C++");
			Lib.println ("  [linux] -64 : Compile for 64-bit instead of 32-bit");
			Lib.println ("  [android] -arm7 : Compile for arm-7a and arm5");
			Lib.println ("  [android] -arm7-only : Compile for arm-7a for testing");
			Lib.println ("  [ios|blackberry] -simulator : Build/test for the device simulator");
			Lib.println ("  [ios] -simulator -ipad : Build/test for the iPad Simulator");
			Lib.println ("  [flash] -web : Generate web template files");
			Lib.println ("  [flash] -chrome : Generate Google Chrome app template files");
			Lib.println ("  [flash] -opera : Generate an Opera Widget");
			Lib.println ("  [html5] -minify : Minify output using the Google Closure compiler");
			Lib.println ("  [html5] -minify -yui : Minify output using the YUI compressor");
			Lib.println ("  (display) -hxml : Print HXML information for the project");
			Lib.println ("  (display) -nmml : Print NMML information for the project");
			Lib.println ("  (generate) -java-externs : Generate Haxe classes from compiled Java");
			Lib.println ("  (run|test) -args a0 a1 ... : Pass remaining arguments to executable");
			
			return;
			
		} else if (command == "copy-if-newer") {
			
			if (words.length != 2) {
				
				argumentError ("Incorrect number of arguments for command '" + command + "'");
				return;
				
			}
			
			FileHelper.copyIfNewer (words[0], words[1]);
			
		} else if (command == "setup") {
			
			if (words.length == 0) {
				
				PlatformSetup.run ();
				
			} else if (words.length == 1) {
				
				PlatformSetup.run (words[0]);
				
			} else {
				
				argumentError ("Incorrect number of arguments for command '" + command + "'");
				return;
				
			}
			
		} else if (command == "generate") {
			
			if (targetFlags.exists ("java-externs")) {
				
				if (words.length != 2) {
					
					argumentError ("To use 'generate -java-externs' you need to provide two arguments: an input path with compiled Java classes, and an output directory");
					return;
					
				}
				
				new GenerateJavaExterns (words[0], words[1]);
				
			}
	
		} else if (command == "new") {
			
				if (words.length != 1 || words[0].split(".").pop()!="nmml" ) {
					
					argumentError ("You should specify the output nmml file after the 'new' command.");
					return;
					
				}
				
	         for (key in userDefines.keys ())
                defines.set(key,userDefines.get(key));
			
				new NewProject (nme,words[0], defines);
				
		} else {
			
			if (words.length != 2) {
				
				if (command != "document" || (command == "document" && words.length != 1)) {
					
					argumentError ("Incorrect number of arguments for command '" + command + "'");
					return;
					
				}
				
			}
			
			if (!FileSystem.exists (words[0])) {
				
				argumentError ("You must specify an NMML file when using the '" + command + "' command");
				return;
				
			}
			
			for (key in Sys.environment ().keys ()) {
				
				defines.set (key, Sys.getEnv (key));
				
			}
			
			if (!defines.exists ("NME_CONFIG")) {
				
				defines.set ("NME_CONFIG", ".hxcpp_config.xml");
				
			}
			
			var target = "";
			
			if (words.length > 1) {
				
				target = words[1].toLowerCase ();
				
			}
			
			var projectFile = words[0];
			var cacheCwd = Sys.getCwd ();
			
			try { Sys.setCwd (Path.directory (projectFile)); } catch (e:Dynamic) {}
			
			create (nme, command, defines, userDefines, includePaths, projectFile, target, targetFlags, debug, passArgs);
			
			try { Sys.setCwd (cacheCwd); } catch (e:Dynamic) {}
			
		}
		
	}
	
	
	private static var nme_error_output = Loader.load ("nme_error_output", 1);
	
	
}
