package;


import haxe.Unserializer;
import haxe.io.Path;
import haxe.rtti.Meta;
import platforms.AndroidPlatform;
import platforms.BlackBerryPlatform;
import platforms.IOSPlatform;
import platforms.IPlatformTool;
import platforms.LinuxPlatform;
import platforms.MacPlatform;
import sys.io.File;
import sys.FileSystem;
	
	
class CommandLineTools {
	
	
	public static var additionalArguments:Array <String>;
	public static var architectures:Array <Architecture>;
	public static var command:String;
	public static var debug:Bool;
	public static var haxeflags:Array <String>;
	public static var includePaths:Array <String>;
	public static var nme:String;
	public static var project:NMEProject;
	public static var targetFlags:Hash <String>;
	public static var traceEnabled:Bool;
	public static var userDefines:Hash <String>;
	public static var version:String;
	public static var words:Array <String>;
	
	
	private static function buildProject () {
		
		var project = initializeProject ();
		var platform:IPlatformTool = null;
		var metaFields = null;
		
		LogHelper.info ("", "Using target platform: " + project.target);
		
		switch (project.target) {
			
			case Platform.ANDROID:
				
				platform = new AndroidPlatform ();
				metaFields = Meta.getFields (AndroidPlatform);
				
			case Platform.BLACKBERRY:
				
				platform = new BlackBerryPlatform ();
				metaFields = Meta.getFields (BlackBerryPlatform);
			
			case Platform.IOS:
				
				platform = new IOSPlatform ();
				metaFields = Meta.getFields (IOSPlatform);
			
			case Platform.WEBOS:
				
				//
			
			case Platform.WINDOWS:
				
				//
			
			case Platform.MAC:
				
				platform = new MacPlatform ();
				metaFields = Meta.getFields (MacPlatform);
				
			case Platform.LINUX:
				
				platform = new LinuxPlatform ();
				metaFields = Meta.getFields (LinuxPlatform);
				
			case Platform.FLASH:
				
				//
				
			case Platform.HTML5:
				
				//
			
		}
		
		if (platform != null) {
			
			var command = project.command.toLowerCase ();
			
			if (!Reflect.hasField (metaFields.clean, "ignore") && (command == "clean" || targetFlags.exists ("clean"))) {
				
				LogHelper.info ("", "Running command: clean");
				platform.clean (project);
				
			}
			
			if (!Reflect.hasField (metaFields.update, "ignore") && (command == "update" || command == "build" || command == "test")) {
				
				LogHelper.info ("", "Running command: update");
				platform.update (project);
				
			}
			
			if (!Reflect.hasField (metaFields.build, "ignore") && (command == "build" || command == "test")) {
				
				LogHelper.info ("", "Running command: build");
				platform.build (project);
				
			}
			
			if (!Reflect.hasField (metaFields.install, "ignore") && (command == "install" || command == "run" || command == "test")) {
				
				LogHelper.info ("", "Running command: install");
				platform.install (project);
				
			}
		
			if (!Reflect.hasField (metaFields.run, "ignore") && (command == "run" || command == "rerun" || command == "test")) {
				
				LogHelper.info ("", "Running command: run");
				platform.run (project, additionalArguments);
				
			}
		
			if (!Reflect.hasField (metaFields.trace, "ignore") && (command == "test" || command == "trace")) {
				
				if (traceEnabled || command == "trace") {
					
					LogHelper.info ("", "Running command: trace");
					platform.trace (project);
					
				}
				
			}
			
		}
		
	}
	
	
	private static function createTemplate () {
		
		
		
	}
	
	
	private static function document ():Void {
	
	
	}
	
	
	private static function displayHelp ():Void {
		
		Sys.println ("NME Command-Line Tools (" + version + ")");
		Sys.println ("");
		Sys.println (" Usage : nme setup (target)");
		Sys.println (" Usage : nme help");
		Sys.println (" Usage : nme [clean|update|build|run|test|display] <project> (target) [options]");
		Sys.println (" Usage : nme document <project> (target)");
		Sys.println (" Usage : nme generate <args> [options]");
		Sys.println (" Usage : nme new file.nmml name1=value1 name2=value2 ...");
		Sys.println ("");
		Sys.println (" Commands : ");
		Sys.println ("");
		Sys.println ("  setup : Setup NME or a specific target");
		Sys.println ("  help : Show this information");
		Sys.println ("  clean : Remove the target build directory if it exists");
		Sys.println ("  update : Copy assets for the specified project/target");
		Sys.println ("  build : Compile and package for the specified project/target");
		Sys.println ("  run : Install and run for the specified project/target");
		Sys.println ("  test : Update, build and run in one command");
		Sys.println ("  display : Display information for the specified project/target");
		Sys.println ("  document : Generate documentation using haxedoc");
		Sys.println ("  generate : Tools to help create source code automatically");
		Sys.println ("");
		Sys.println (" Targets : ");
		Sys.println ("");
		Sys.println ("  android : Create Google Android applications");
		Sys.println ("  blackberry : Create BlackBerry applications");
		Sys.println ("  cpp : Create application for the system you are compiling on");
		Sys.println ("  flash : Create SWF applications for Adobe Flash Player");
		Sys.println ("  html5 : Create HTML5 canvas applications");
		Sys.println ("  ios : Create Apple iOS applications");
		Sys.println ("  linux : Create Linux applications");
		Sys.println ("  mac : Create Apple Mac OS X applications");
		Sys.println ("  webos : Create HP webOS applications");
		Sys.println ("  windows : Create Microsoft Windows applications");
		Sys.println ("");
		Sys.println (" Options : ");
		Sys.println ("");
		Sys.println ("  -debug : Use debug configuration instead of release");
		Sys.println ("  -verbose : Print additional information (when available)");
		Sys.println ("  -clean : Add a \"clean\" action before running the current command");
		Sys.println ("  -xml : Generate XML type information, can be used with \"document\"");
		Sys.println ("  [windows|mac|linux] -neko : Build with Neko instead of C++");
		Sys.println ("  [linux] -64 : Compile for 64-bit instead of 32-bit");
		Sys.println ("  [android] -arm7 : Compile for arm-7a and arm5");
		Sys.println ("  [android] -arm7-only : Compile for arm-7a for testing");
		Sys.println ("  [ios|blackberry] -simulator : Build/test for the device simulator");
		Sys.println ("  [ios] -simulator -ipad : Build/test for the iPad Simulator");
		Sys.println ("  [flash] -web : Generate web template files");
		Sys.println ("  [flash] -chrome : Generate Google Chrome app template files");
		Sys.println ("  [flash] -opera : Generate an Opera Widget");
		Sys.println ("  [html5] -minify : Minify output using the Google Closure compiler");
		Sys.println ("  [html5] -minify -yui : Minify output using the YUI compressor");
		Sys.println ("  (display) -hxml : Print HXML information for the project");
		Sys.println ("  (display) -nmml : Print NMML information for the project");
		Sys.println ("  (generate) -java-externs : Generate Haxe classes from compiled Java");
		Sys.println ("  (run|test) -args a0 a1 ... : Pass remaining arguments to executable");
		
	}
	
	
	private static function displayInfo ():Void {
		
		Sys.println ("NME Command-Line Tools (" + version + ")");
		Sys.println ("Use \"nme setup\" to configure NME or \"nme help\" for more commands");
		
	}
	
	
	private static function findProjectFile (path:String):String {
		
		if (FileSystem.exists (PathHelper.combine (path, "Project.hx"))) {
			
			return PathHelper.combine (path, "Project.hx");
			
		} else if (FileSystem.exists (PathHelper.combine (path, "project.nmml"))) {
			
			return PathHelper.combine (path, "project.nmml");
			
		} else if (FileSystem.exists (PathHelper.combine (path, "project.xml"))) {
			
			return PathHelper.combine (path, "project.xml");
			
		} else {
			
			var files = FileSystem.readDirectory (path);
			var matches = [];
			
			for (file in files) {
				
				var path = PathHelper.combine (path, file);
				
				if (FileSystem.exists (path) && !FileSystem.isDirectory (path)) {
					
					if ((Path.extension (file) == "nmml" && file != "include.nmml") || Path.extension (file) == "hx") {
						
						matches.push (path);
						
					}
					
				}
				
			}
			
			if (matches.length > 0) {
				
				return matches[0];
				
			}
			
		}
		
		return "";
		
	}
	
	
	private static function generate ():Void {
		
		
		
	}
	
	
	public static function getHXCPPConfig ():NMEProject {
		
		var environment = Sys.environment ();
		var config = "";
		
		if (environment.exists ("HXCPP_CONFIG")) {
			
			config = environment.get ("HXCPP_CONFIG");
			
		} else {
			
			var home = "";
			
			if (environment.exists ("HOME")) {
				
				home = environment.get ("HOME");
				
			} else if (environment.exists ("USERPROFILE")) {
				
				home = environment.get ("USERPROFILE");
				
			} else {
				
				LogHelper.warn ("HXCPP config might be missing (Environment has no \"HOME\" variable)");
				
				return null;
				
			}
			
			config = home + "/.hxcpp_config.xml";
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				config = config.split ("/").join ("\\");
				
			}
			
		}
		
		if (FileSystem.exists (config)) {
			
			LogHelper.info ("", "Reading HXCPP config: " + config);
			
			return new NMMLParser (config);
			
		} else {
			
			LogHelper.warn ("", "Could not read HXCPP config: " + config);
			
		}
		
		return null;
		
	}
	
	
	private static function getVersion ():String {
		
		for (element in Xml.parse (File.getContent (nme + "/haxelib.xml")).firstElement ().elements ()) {
			
			if (element.nodeName == "version") {
				
				return element.get ("name");
				
			}
			
		}
		
		return "";
		
	}
	
	
	#if (neko && haxe_210)
	public static function __init__ () {
		
		// Fix for library search paths
		
		var path = PathHelper.getHaxelib ("nme") + "ndll/";
		
		switch (PlatformHelper.hostPlatform) {
			
			case Platform.WINDOWS:
				
				untyped $loader.path = $array (path + "Windows/", $loader.path);
				
			case Platform.MAC:
				
				untyped $loader.path = $array (path + "Mac/", $loader.path);
				
			case Platform.LINUX:
				
				if (PlatformHelper.hostArchitecture == Architecture.X86_64) {
					
					untyped $loader.path = $array (path + "Linux64/", $loader.path);
					
				} else {
					
					untyped $loader.path = $array (path + "Linux/", $loader.path);
					
				}
			
			default:
			
		}
		
	}
	#end
	
	
	private static function initializeProject ():NMEProject {
		
		LogHelper.info ("", "Initializing project...");
		
		var projectFile = "";
		var targetName = "";
		
		if (words.length == 2) {
			
			if (FileSystem.exists (words[0])) {
				
				if (FileSystem.isDirectory (words[0])) {
					
					projectFile = findProjectFile (words[0]);
					
				} else {
					
					projectFile = words[0];
					
				}
				
			}
			
			targetName = words[1].toLowerCase ();
			
		} else {
			
			projectFile = findProjectFile (Sys.getCwd ());
			targetName = words[0].toLowerCase ();
			
		}
		
		if (projectFile == "") {
			
			LogHelper.error ("You must have a \"project.nmml\" file or specify another NMML file when using the '" + command + "' command");
			return null;
			
		} else {
			
			LogHelper.info ("", "Using project file: " + projectFile);
			
		}
		
		var target = null;
		
		switch (targetName) {
			
			case "cpp":
				
				target = PlatformHelper.hostPlatform;
				targetFlags.set ("cpp", "");
				
			case "neko":
				
				target = PlatformHelper.hostPlatform;
				targetFlags.set ("neko", "");
				
			case "iphone", "iphoneos":
				
				target = Platform.IOS;
				
			case "iphonesim":
				
				target = Platform.IOS;
				targetFlags.set ("simulator", "");
			
			default:
				
				try {
					
					target = Type.createEnum (Platform, targetName.toUpperCase ());
					
				} catch (e:Dynamic) {
					
					LogHelper.error ("\"" + targetName + "\" is an unknown target");
					
				}
		
		}
		
		NMEProject._command = command;
		NMEProject._debug = debug;
		NMEProject._target = target;
		NMEProject._targetFlags = targetFlags;
		NMEProject._templatePaths = [ nme + "/templates/default", nme + "/tools/command-line" ];
		
		try { Sys.setCwd (Path.directory (projectFile)); } catch (e:Dynamic) {}
		
		var project = null;
		
		if (Path.extension (projectFile) == "nmml" || Path.extension (projectFile) == "xml") {
			
			project = new NMMLParser (Path.withoutDirectory (projectFile), userDefines, includePaths);
			
		} else {
			
			var path = FileSystem.fullPath (Path.withoutDirectory (projectFile));
			var name = Path.withoutDirectory (Path.withoutExtension (projectFile));
			
			ProcessHelper.runCommand ("", "haxe", [ "-main", name, "-neko", "~/haxe.n", "-lib", "nme", "-cp", "/Users/joshua/Development/Haxe/nme/tools/project", "-cp", "/Users/joshua/Development/Haxe/nme/tools/helpers" ]);
			
			var process = new sys.io.Process ("neko", [ "/Users/joshua/haxe.n" ]);
			var output = process.stdout.readAll ().toString ();
			var error = process.stderr.readAll ().toString ();
			process.exitCode ();
			process.close ();
			
			var unserializer = new Unserializer (output);
			unserializer.setResolver (cast { resolveEnum: Type.resolveEnum, resolveClass: resolveClass });
			
			project = unserializer.unserialize ();
			
			//Sys.println (output);
			
			//var project = NMEProject.main ("NMML
			
		}
		
		
		trace (project);
		
		
		project.command = command;
		project.debug = debug;
		project.target = target;
		project.targetFlags = targetFlags;
		project.templatePaths = project.templatePaths.concat ([ nme + "/templates/default", nme + "/tools/command-line" ]);
		
		
		
		
		
		
		var config = getHXCPPConfig ();
		project.merge (config);
		
		project.architectures = project.architectures.concat (architectures);
		project.haxeflags = project.haxeflags.concat (haxeflags);
		project.haxedefs.push ("nme_install_tool");
		
		for (key in userDefines.keys ()) {
			
			var value = userDefines.get (key);
			
			if (value == "") {
				
				project.haxedefs.push (key);
				
			}
			
		}
		
		return project;
		
	}
	
	
	private static function resolveClass (name:String):Class <Dynamic> {
		
		if (name.toLowerCase ().indexOf ("project") > -1) {
			
			return NMEProject;
			
		} else {
			
			return Type.resolveClass (name);
			
		}
		
	}
	
	
	public static function main ():Void {
		
		additionalArguments = new Array <String> ();
		architectures = new Array <Architecture> ();
		command = "";
		debug = false;
		haxeflags = new Array <String> ();
		includePaths = new Array <String> ();
		targetFlags = new Hash <String> ();
		traceEnabled = true;
		userDefines = new Hash <String> ();
		words = new Array <String> ();
		
		processArguments ();
		version = getVersion ();
		
		LogHelper.info ("", StringHelper.underline ("NME Command-Line Tools (" + version + ")"));
		
		/*if (userDefines.exists ("debug")) {
			
			debug = true;
			
		}
		
		if (Sys.environment ().exists ("HOME")) {
			
			includePaths.push (Sys.getEnv ("HOME"));
			
		}
		
		if (Sys.environment ().exists ("USERPROFILE")) {
			
			includePaths.push (Sys.getEnv ("USERPROFILE"));
			
		}
		
		includePaths.push (nme + "/tools/command-line");*/
		
		switch (command) {
			
			case "":
				
				displayInfo ();
				
			case "help":
				
				displayHelp ();
				
			case "setup":
				
				platformSetup ();
			
			case "document":
				
				document ();
				
			case "generate":
				
				generate ();
				
			case "create":
				
				createTemplate ();
				
			case "clean", "update", "display", "build", "run", "rerun", "install", "uninstall", "trace", "test":
				
				if (words.length < 1 || words.length > 2) {
					
					LogHelper.error ("Incorrect number of arguments for command '" + command + "'");
					return;
					
				}
				
				buildProject ();
			
			case "installer", "copy-if-newer":
				
				// deprecated?
				
			default:
				
				LogHelper.error ("'" + command + "' is not a valid command");
			
		}
		
	}
	
	
	private static function processArguments ():Void {
		
		var arguments = Sys.args ();
		
		if (arguments.length > 0) {
			
			// When the command-line tools are called from haxelib, 
			// the last argument is the project directory and the
			// path to NME is the current working directory 
			
			var lastArgument = new Path (arguments[arguments.length - 1]).toString ();
			
			if (((StringTools.endsWith (lastArgument, "/") && lastArgument != "/") || StringTools.endsWith (lastArgument, "\\")) && !StringTools.endsWith (lastArgument, ":\\")) {
				
				lastArgument = lastArgument.substr (0, lastArgument.length - 1);
				
			}
			
			if (FileSystem.exists (lastArgument) && FileSystem.isDirectory (lastArgument)) {
				
				nme = Sys.getCwd ();
				
				var lastCharacter = nme.substr (-1, 1);
				
				if (lastCharacter == "/" || lastCharacter == "\\") {
						
					nme = nme.substr (0, -1);
					
				}
				
				Sys.setCwd (lastArgument);
				arguments.pop ();
				
			}
			
		}
		
		var catchArguments = false;
		var catchHaxeFlag = false;
		
		for (argument in arguments) {
			
			var equals = argument.indexOf ("=");
			
			if (catchHaxeFlag) {
				
				haxeflags.push (argument);
				catchHaxeFlag = false;
				
			} else if (catchArguments) {
				
				additionalArguments.push (argument);
				
			} else if (equals > 0) {
				
				if (argument.substr (0, 2) == "-D") {
					
					userDefines.set (argument.substr (2, equals - 2), argument.substr (equals + 1));
					
				} else {
					
					userDefines.set (argument.substr (0, equals), argument.substr (equals + 1));
					
				}
				
			} else if (argument.substr (0, 4) == "-arm") {
				
				var name = argument.substr (1).toUpperCase ();
				var value = Type.createEnum (Architecture, name);
				
				if (value != null) {
					
					architectures.push (value);
					
				}
				
			} else if (argument == "-64") {
				
				architectures.push (Architecture.X86_64);
				
			} else if (argument.substr (0, 2) == "-D") {
				
				userDefines.set (argument.substr (2), "");
				
			} else if (argument.substr (0, 2) == "-l") {
				
				includePaths.push (argument.substr (2));
				
			} else if (argument == "-v" || argument == "-verbose") {
				
				LogHelper.verbose = true;
				
			} else if (argument == "-args") {
				
				catchArguments = true;
				
			} else if (argument == "-notrace") {
				
				traceEnabled = false;
				
			} else if (argument == "-debug") {
				
				debug = true;
				
			} else if (command.length == 0) {
				
				command = argument;
			
			} else if (argument.substr (0, 1) == "-") {
				
				if (argument.substr (1, 1) == "-") {
					
					haxeflags.push (argument);
					
					if (argument == "--remap" || argument == "--connect") {
						
						catchHaxeFlag = true;
						
					}
					
				} else {
					
					targetFlags.set (argument.substr (1), "");
					
				}
				
			} else {
				
				words.push (argument);
				
			}
			
		}
		
	}
	
	
	private static function platformSetup ():Void {
		
		
		
	}
	
	
}