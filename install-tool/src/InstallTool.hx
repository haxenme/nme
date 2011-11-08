import documentation.DocumentationGenerator;
import haxe.io.Eof;
import installers.AndroidInstaller;
import installers.CPPInstaller;
import installers.FlashInstaller;
import installers.HTML5Installer;
import installers.InstallerBase;
import installers.IOSInstaller;
import installers.NekoInstaller;
import installers.WebOSInstaller;
import setup.PlatformSetup;
import neko.FileSystem;
import neko.io.File;
import neko.io.Path;
import neko.Lib;
import neko.Sys;


class InstallTool {
	
	
	public static var isMac = false;
	public static var isLinux = false;
	public static var isWindows = false;
	public static var nme:String = "";
	public static var traceEnabled:Bool = true;
	public static var verbose = false;
	
	
	static public function create (nme:String, command:String, defines:Hash <String>, includePaths:Array <String>, projectFile:String, target:String, targetFlags:Hash <String>, debug:Bool) {
		
		var installer:InstallerBase = null;
		
		if (target == "windows" || target == "mac" || target == "linux") {
			
			if (targetFlags.exists ("neko") || (!defines.exists (target) && !targetFlags.exists ("cpp"))) {
				
				targetFlags.set (target, "");
				target = "neko";
				
			} else {
				
				target = "cpp";
				
			}
			
		}
		
		if (command == "document") {
			
			installer = new DocumentationGenerator ();
			
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
				
				default:
					
					Lib.println ("Error : The specified target is not supported: " + target);
					return;
				
			}
			
		}
		
		installer.create (nme, command, defines, includePaths, projectFile, target, targetFlags, debug);
		
	}
	
	
	private static function argumentError (error:String):Void {
		
		Lib.println (error);
		/*Lib.println ("-------------------------------");
		Lib.println ("Usage :  haxelib run nme [-v] COMMAND ...");
		Lib.println (" COMMAND : copy-if-newer source destination");
		Lib.println (" COMMAND : (update|document) build.nmml [-DFLAG -Dname=val... ]");
		Lib.println (" COMMAND : (build|update|run|rerun|test) [-debug] build.nmml target");
		Lib.println (" COMMAND : (trace|uninstall) build.nmml target");*/
		
	}
	
	
	public static function copyIfNewer (source:String, destination:String) {
		
		if (!isNewer (source, destination)) {
			
			return;
			
		}
		
		if (verbose) {
			
			Lib.println ("Copy " + source + " to " + destination);
			
		}
		
		File.copy (source, destination);
		
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
	
	
	public static function isNewer (source:String, destination:String):Bool {
		
		if (source == null || !FileSystem.exists (source)) {
			
			throw ("Error: " + source + " does not exist");
			return false;
			
		}
		
		if (FileSystem.exists (destination)) {
			
			if (FileSystem.stat (source).mtime.getTime () < FileSystem.stat (destination).mtime.getTime ()) {
				
				return false;
				
			}
			
		}
		
		return true;
		
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
					
					print("mkdir " + total);
					
					FileSystem.createDirectory (total);
					
				}
				
			}
			
		}
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
	}
	
	
	public static function print (message:String):Void {
		
		if (verbose) {
			
			Lib.println(message);
			
		}
		
	}
	

	public static function runCommand (path:String, command:String, args:Array<String>) {
		
		var oldPath:String = "";
		
		if (path != "") {
			
			print("cd " + path);
			
			oldPath = Sys.getCwd ();
			Sys.setCwd (path);
			
		}
		
		print(command + (args==null ? "": " " + args.join(" ")) );
		
		var result:Dynamic = Sys.command (command, args);
		
		if (result == 0)
			print("Ok.");
			
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
		if (result != 0) {
			
			throw ("Error running: " + command + " " + args.join (" ") + path);
			
		}
		
	}
	
	
	private static function runSetup (target:String = "") {
		
		try {
			
			switch (target) {
				
				case "android":
					
					PlatformSetup.setupAndroid ();
				
				case "blackberry":
					
					PlatformSetup.setupBlackBerry ();
				
				case "webos":
					
					PlatformSetup.setupWebOS ();
				
				case "windows":
					
					if (isWindows) {
						
						PlatformSetup.setupWindows ();
						
					}
				
				case "":
					
					PlatformSetup.installNME ();
				
				default:
					
					Lib.println ("No setup is required for " + target + ", or it is not a valid target");
					return;
				
			}
			
		} catch (e:Eof) {
			
			
			
		}
		
	}
	
	
	public static function main () {
		
		var command:String = "";
		var debug:Bool = false;
		var defines = new Hash <String> ();
		var includePaths = new Array <String> ();
		var targetFlags = new Hash <String> ();
		
		includePaths.push (".");
		
		var args:Array <String> = Sys.args ();
		
		if (args.length > 0) {
			
			// When called from haxelib, the last argument is the calling directory. The path to nme is set as the current working directory 
			
			var lastArgument:String = new Path (args[args.length - 1]).toString ();
			
			if (lastArgument.substr (-1) == "/" || lastArgument.substr (-1) == "\\") {
				
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
			
			defines.set ("macos", "1");
			defines.set ("NME_HOST", "darwin-x86");
			isMac = true;
			
		}
		
		var words:Array <String> = new Array <String> ();
		
		for (arg in args) {
			
			var equals:Int = arg.indexOf ("=");
			
			if (equals > 0) {
				
				defines.set (arg.substr (0, equals), arg.substr (equals + 1));
				
			} else if (arg == "-64") {
				
				defines.set ("NME_64", "1");
				
			} else if (arg.substr (0, 2) == "-D") {
				
				defines.set (arg.substr (2), "");
				
			} else if (arg.substr (0, 2) == "-l") {
				
				includePaths.push (arg.substr (2));
				
			} else if (arg == "-v" || arg == "-verbose") {
				
				verbose = true;
				
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
		
		if (Sys.environment ().exists ("HOME")) {
			
			includePaths.push (Sys.getEnv ("HOME"));
			
		}
		
		if (Sys.environment ().exists ("USERPROFILE")) {
			
			includePaths.push (Sys.getEnv ("USERPROFILE"));
			
		}
		
		includePaths.push (nme + "/install-tool");
		
		var validCommands:Array <String> = [ "setup", "help", "copy-if-newer", "run", "rerun", "update", "test", "build", "installer", "uninstall", "trace", "document" ];
		
		if (!Lambda.exists (validCommands, function (c) return command == c)) {
			
			if (command != "") {
				
				argumentError ("Unknown command: " + command);
				return;
				
			}
			
		}
		
		if (command == "") {
			
			Lib.println ("NME Command-Line Tools (3.1.0)");
			Lib.println ("Use \"nme setup\" to configure NME or \"nme help\" for more commands");
			
		} else if (command == "help") {
			
			Lib.println ("NME Command-Line Tools (3.1.0)");
			Lib.println ("");
			Lib.println (" Usage : nme setup (target)");
			Lib.println (" Usage : nme help");
			Lib.println (" Usage : nme [update|build|run|test] <project> <target> [options]");
			Lib.println (" Usage : nme document <project> (target)");
			Lib.println ("");
			Lib.println (" Commands : ");
			Lib.println ("");
			Lib.println ("  setup : Setup NME or a specific target");
			Lib.println ("  help : Show this information");
			Lib.println ("  update : Copy assets for the specified project/target");
			Lib.println ("  build : Compile and package for the specified project/target");
			Lib.println ("  run : Install and run for the specified project/target");
			Lib.println ("  test : Update, build and run in one command");
			Lib.println ("  document : Generate documentation using haxedoc");
			Lib.println ("");
			Lib.println (" Targets : ");
			Lib.println ("");
			Lib.println ("  android : Create Google Android applications");
			Lib.println ("  flash : Create SWF applications for Adobe Flash Player");
			Lib.println ("  html5 : Create HTML5 canvas applications using Jeash");
			Lib.println ("  ios : Create Apple iOS applications");
			Lib.println ("  linux : Create Linux applications");
			Lib.println ("  mac : Create Apple Mac OS X applications");
			Lib.println ("  webos : Create HP webOS applications");
			Lib.println ("  windows : Create Microsoft Windows applications");
			Lib.println ("");
			Lib.println (" Options : ");
			Lib.println ("");
			Lib.println ("  -verbose : Print additional information (when available)");
			Lib.println ("  -debug : Use debug configuration instead of release");
			Lib.println ("  -xml : Generate XML type information, for use with document");
			Lib.println ("  [windows|mac|linux] -neko : Build with Neko instead of C++");
			Lib.println ("  [linux] -64 : Compile for 64-bit instead of 32-bit");
			Lib.println ("  [flash] -web : Generate web template files");
			Lib.println ("  [flash] -chrome : Generate Google Chrome app template files");
			Lib.println ("  [flash] -opera : Generate an Opera Widget");
			Lib.println ("  [ios] -simulator : Build/test for the iPhone Simulator");
			Lib.println ("  [ios] -simulator -ipad : Builds/test for the iPad Simulator");
			
			return;
			
		} else if (command == "copy-if-newer") {
			
			if (words.length != 2) {
				
				argumentError ("Wrong number of arguments for command: " + command);
				return;
				
			}
			
			copyIfNewer (words[0], words[1]);
			
		} else if (command == "setup") {
			
			if (words.length == 0) {
				
				runSetup ();
				
			} else if (words.length == 1) {
				
				runSetup (words[0]);
				
			} else {
				
				argumentError ("Wrong number of arguments for command: " + command);
				return;
				
			}
			
		} else {
			
			if (words.length != 2) {
				
				if (command != "document" || (command == "document" && words.length != 1)) {
					
					argumentError ("Wrong number of arguments for command: " + command);
					return;
					
				}
				
			}
			
			if (!FileSystem.exists (words[0])) {
				
				argumentError ("Error using command: " + command + ", you must specify a *.nmml file");
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
				
				target = words[1];
				
			}
			
			create (nme, command, defines, includePaths, words[0], target, targetFlags, debug);
			
		}
		
	}
	
	
}