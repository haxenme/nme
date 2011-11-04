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
					
					Lib.println ("The specified target is not supported: " + target);
					return;
				
			}
			
		}
		
		installer.create (nme, command, defines, includePaths, projectFile, target, targetFlags, debug);
		
	}
	
	
	private static function argumentError (error:String):Void {
		
		Lib.println (error);
		Lib.println ("Usage :  haxelib run nme [-v] COMMAND ...");
		Lib.println (" COMMAND : copy-if-newer source destination");
		Lib.println (" COMMAND : (update|document) build.nmml [-DFLAG -Dname=val... ]");
		Lib.println (" COMMAND : (build|update|run|rerun|test) [-debug] build.nmml target");
		Lib.println (" COMMAND : (trace|uninstall) build.nmml target");
		
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
	
	
	private static function getDefines (names:Array <String>, descriptions:Array <String>):Hash <String> {
		
		var parser = new InstallerBase ();
		parser.parseHXCPPConfig ();
		
		var defines:Hash <String> = parser.defines;
		var env = Sys.environment ();
		var path = "";
		
		if (!defines.exists ("HXCPP_CONFIG")) {
			
			var home = "";
			
			if (env.exists("HOME"))
				home = env.get("HOME");
			else if (env.exists("USERPROFILE"))
				home = env.get("USERPROFILE");
			else
			{
				Lib.println("Warning: No 'HOME' variable set - .hxcpp_config.xml might be missing.");
				return null;
			}
			
			defines.set ("HXCPP_CONFIG", home + "/.hxcpp_config.xml");
			
		}
		
		var values = new Array <String> ();
		
		for (i in 0...names.length) {
			
			var name = names[i];
			var description = descriptions[i];
			var value = "";
			
			if (defines.exists (name)) {
				
				value = defines.get (name);
				
			} else if (env.exists (name)) {
				
				value = Sys.getEnv (name);
				
			}
			
			value = param (description + " [" + value + "]");
			
			if (value != "" && value != Sys.getEnv (name)) {
				
				defines.set (name, value);
				
			}
			
		}
		
		return defines;
		
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
	
	
	private static function link (dir, file, dest) {
		Sys.command("rm -rf "+dest+"/"+file);
		Sys.command("ln -s "+ "/usr/lib" +"/"+dir+"/"+file+" "+dest+"/"+file);
	}
	
	
	private static function param (name, ?passwd) {
		Lib.print(name+" : ");
		if( passwd ) {
			var s = new StringBuf();
			var c;
			while( (c = neko.io.File.getChar(false)) != 13 )
				s.addChar(c);
			print("");
			return s.toString();
		}
		try {
			return neko.io.File.stdin().readLine();
		} catch (e:Eof) {
			return "";
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
		
		switch (target) {
			
			case "android":
				
				var defines = getDefines ([ "ANDROID_SDK", "ANDROID_NDK_ROOT", "ANT_HOME", "JAVA_HOME" ], [ "Path to Android SDK", "Path to Android NDK", "Path to Apache Ant", "Path to Java JDK" ]);
				
				if (defines != null) {
					
					writeConfig (defines.get ("HXCPP_CONFIG"), defines);
					
				}
			
			case "blackberry":
				
				var defines = getDefines ([ "BLACKBERRY_SDK_ROOT" ], [ "Path to BlackBerry Native SDK" ]);
				
				if (defines != null) {
					
					writeConfig (defines.get ("HXCPP_CONFIG"), defines);
					
				}
			
			case "":
				
				if (isWindows) {
					
					File.copy (nme + "\\install-tool\\bin\\nme.bat", "C:\\Motion-Twin\\haxe\\nme.bat");
					
				} else {
					
					File.copy (nme + "/install-tool/bin/nme.sh", "/usr/lib/haxe/nme");
					Sys.command ("chmod", [ "755", "/usr/lib/haxe/nme" ]);
					link ("haxe", "nme", "/usr/bin");
					
				}
			
			default:
				
				Lib.println ("No setup is required for " + target + ", or it is not a valid target");
				return;
			
		}
		
	}
	
	
	private static function writeConfig (path:String, defines:Hash <String>):Void {
		
		var newContent = "";
		var definesText = "";
		
		for (key in defines.keys ()) {
			
			if (key != "HXCPP_CONFIG") {
				
				definesText += "		<set name=\"" + key + "\" value=\"" + defines.get (key) + "\" />\n";
				
			}
			
		}
		
		if (FileSystem.exists (path)) {
			
			var input = File.read (path, false);
			var bytes = input.readAll ();
			input.close ();
			var content = bytes.readString (0, bytes.length);
			
			var startIndex = content.indexOf ("<section id=\"vars\">");
			var endIndex = content.indexOf ("</section>", startIndex);
			
			newContent += content.substr (0, startIndex) + "<section id=\"vars\">\n		\n";
			newContent += definesText;
			newContent += "		\n	" + content.substr (endIndex);
			
		} else {
			
			newContent += "<xml>\n\n";
			newContent += "	<section id=\"vars\">\n\n";
			newContent += definesText;
			newContent += "	</section>\n\n</xml>";
			
		}
		
		var output = File.write (path, false);
		output.writeString (newContent);
		output.close ();
		
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
		
		var validCommands:Array <String> = [ "setup", "copy-if-newer", "run", "rerun", "update", "test", "build", "installer", "uninstall", "trace", "document" ];
		
		if (!Lambda.exists (validCommands, function (c) return command == c)) {
			
			if (command != "") {
				
				argumentError ("Unknown command: " + command);
				return;
				
			}
			
		}
		
		if (command == "copy-if-newer") {
			
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
