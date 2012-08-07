package installers;


import data.Asset;
import data.LaunchImage;
import data.Icon;
import data.Icons;
import data.NDLL;
import format.SWF;
import haxe.Stack;
import haxe.Template;
import haxe.io.Path;
import haxe.xml.Fast;
import helpers.PathHelper;
import neko.Lib;
import nme.utils.ByteArray;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;


class InstallerBase {
	
	
	public var defines:Hash <String>;
	
	private var assets:Array <Asset>;
	private var buildDirectory:String;
	private var command:String;
	private var compilerFlags:Array <String>;
	private var context:Dynamic;
	private var debug:Bool;
	private var dependencyNames:Array <String>;
	private var launchImages:Array<LaunchImage>;
	private var icons:Icons;
	private var includePaths:Array <String>;
	private var javaPaths:Array <String>;
	private var ndlls:Array <NDLL>;
	private var allFiles:Array <String>;
	private var NME:String;
	private var projectFile:String;
	private var swfLibraries:Array <Asset>;
	private var target:String;
	private var templatePaths:Array <String>;
	private var sslCaCert:String;
	private var targetFlags:Hash <String>;
	private var args:Array <String>;
	private var iosDeployment:String;
	private var iosBinaries:String;
	private var iosDevices:String;
	private var iosCompiler:String;
	
	private static var varMatch = new EReg("\\${(.*?)}", "");

	
	public function new () {
		
		assets = new Array <Asset> ();
		compilerFlags = new Array <String> ();
		defines = new Hash <String> ();
		dependencyNames = new Array <String> ();
		launchImages = new Array<LaunchImage>();
		icons = new Icons ();
		includePaths = new Array <String> ();
		javaPaths = new Array <String> ();
		allFiles = new Array <String> ();
		ndlls = new Array <NDLL> ();
      sslCaCert = "";
      iosDeployment = "3.2";
      iosBinaries = "armv6";
      iosDevices = "universal";
      iosCompiler = "clang";
		
	}
	
	
	public function create (NME:String, command:String, defines:Hash <String>, userDefines:Hash <String>, includePaths:Array <String>, projectFile:String, target:String, targetFlags:Hash <String>, debug:Bool, args:Array<String>):Void {
		
		this.NME = NME;
		this.command = command;
		this.defines = defines;
		this.includePaths = includePaths;
		this.projectFile = projectFile;
		this.target = target;
		this.targetFlags = targetFlags;
		this.debug = debug;
		this.args = args;
		
		templatePaths = [ NME + "/templates/default/" ];
		
		for (key in userDefines.keys ()) {
			
			var value = userDefines.get (key);
			
			if (value == "") {
				
				compilerFlags.push ("-D " + key);
				
			}
			
			defines.set (key, value);
			
		}
		
		swfLibraries = new Array <Asset> ();
		
		initializeTool ();
		parseHXCPPConfig ();
		parseProjectFile ();
		
		if (defines.get ("APP_PACKAGE").split (".").length < 3) {
			
			error ("Your application package must have at least three segments, like <meta package=\"com.example.myapp\" />");
			
		}
		
		if (command == "trace") {
			
			InstallTool.traceEnabled = true;
			
		}
		
		if (defines.exists ("mobile")) {
			
			compilerFlags.push ("-D mobile");
			
		} else if (defines.exists ("desktop")) {
			
			compilerFlags.push ("-D desktop");
			
		} else if (defines.exists ("web")) {
			
			compilerFlags.push ("-D web");
			
		}
		
		var backgroundColor = defines.get ("WIN_BACKGROUND");
		
		if (backgroundColor.indexOf ("#") == 0) {
			
			backgroundColor = "0x" + backgroundColor.substr (1);
			
		} else if (backgroundColor.indexOf ("0x") == -1) {
			
			backgroundColor = "0x" + backgroundColor;
			
		}
		
		defines.set ("WIN_BACKGROUND", backgroundColor);
		
		// Strip off 0x ....
		setDefault ("WIN_FLASHBACKGROUND", defines.get ("WIN_BACKGROUND").substr (2));
		setDefault ("APP_VERSION_SHORT", defines.get ("APP_VERSION").substr (2));
		setDefault ("XML_DIR", defines.get ("BUILD_DIR") + "/" + target);
		setDefault ("KEY_STORE_TYPE", "pkcs12");
		
		if (defines.exists ("KEY_STORE")) {
			
			setDefault ("KEY_STORE_ALIAS", Path.withoutExtension (Path.withoutDirectory (defines.get ("KEY_STORE"))));
			
		} else if (targetFlags.exists ("air")) {
			
			setDefault ("KEY_STORE", NME + "/tools/command-line/bin/debug.p12");
			setDefault ("KEY_STORE_PASSWORD", "nme");
			
		}
		
		if (defines.exists ("KEY_STORE_PASSWORD")) {
			
			setDefault ("KEY_STORE_ALIAS_PASSWORD", defines.get ("KEY_STORE_PASSWORD"));
		
		}
		
		if (defines.exists ("NME_64")) {
			
			compilerFlags.push ("-D HXCPP_M64");
			
		}
		
		buildDirectory = defines.get ("BUILD_DIR");
		getBuildNumber ((command == "build" || command == "test"));
		
		onCreate ();
		
		if (command == "clean" || targetFlags.exists ("clean")) {
			
			print ("----- CLEAN -----");
			clean ();
			
		}
		
		generateContext ();
		
		// Commands:
		//
		// clean = Remove the build directory if it exists
		// update = Assets or extenal library have changed - files need updating copy files to target directories
		// build = Create files ready to be installed, but do not run.  eg: build server
		// run = run, updating the device is required (eg, android installer)
		// rerun = run, without updating the device
		// test = change is made, needs to be tested:  update, build, run
		
		if (command == "update" || command == "build" || command == "test") {
			
			print ("----- UPDATE -----");
			update ();
			
		}
		
		if (command == "build" || command == "test") {
			
			print ("----- BUILD -----");
			build ();
			
		}
		
		if (command == "run" || command == "test") {
			
			print ("----- UPDATE DEVICE -----");
			updateDevice ();
			
		}
		
		if (command == "run" || command == "rerun" || command == "test") {
			
			print ("----- RUN -----");
			
			run ();
			
		}
		
		if (command == "test" || command == "trace") {
			
			if (InstallTool.traceEnabled || command == "trace") {
				
				print ("----- TRACE -----");
				traceMessages ();
				
			}
			
		}
		
		if (command == "uninstall") {
			
			uninstall ();
			
		}
		
		if (command == "display") {
			
			if (targetFlags.exists ("nmml")) {
				
				displayNMML ();
				
			//} else if (targetFlags.exists ("hxml")) {
			} else {
				
				displayHXML ();
				
			}
			
		}
		
		var validCommands = [ "clean", "update", "build", "test", "run", "rerun", "trace", "uninstall", "document", "display" ];
		
		if (!validCommands.remove (command)) {
			
			error ("Command \"" + command + "\" has not been implemented");
			
		}
		
	}
	
	
	function onCreate ():Void { }
	function useFullClassPaths () { return false; }
	
	function clean () { error ("Clean not implemented."); }
	function update () { error ("Update not implemented."); }
	function build () { error ("Build not implemented."); }
	function run () { error ("Run not implemented."); }
	function updateDevice () { /* Not required on all platforms. */ }
	function install () { error ("Install not implemented."); }
	function traceMessages () { /* Not required on all platforms. */ }
	function uninstall () { error ("Uninstall not implemented."); }
	
	
	private function displayHXML ():Void {
		
		var templateFile = context.HXML_PATH;
		
		var fileContents:String = File.getContent (templateFile);
		var template:Template = new Template (fileContents);
		var result:String = template.execute (context);
		
		Lib.println (result);
		Lib.println ("-D code_completion");
		
	}
	
	
	private function displayNMML ():Void {
		
		var nmml = '<?xml version="1.0" encoding="utf-8"?>\n<project>\n\n';
		var environment = Sys.environment ();
		
		nmml += new Template ('	<meta title="::APP_TITLE::" description="::APP_DESCRIPTION::" package="::APP_PACKAGE::" version="::APP_VERSION::" company="::APP_COMPANY::" />\n\n').execute (context);
		
		nmml += new Template ('	<app main="::APP_MAIN::" file="::APP_FILE::" path="::BUILD_DIR::" preloader="::PRELOADER_NAME::" swf-version="::SWF_VERSION::" />\n\n').execute (context);
		
		nmml += new Template ('	<window width="::WIN_WIDTH::" height="::WIN_HEIGHT::" orientation="::WIN_ORIENTATION::" fps="::WIN_FPS::" background="::WIN_BACKGROUND::" borderless="::WIN_BORDERLESS::" vsync="::WIN_VSYNC::" fullscreen="::WIN_FULLSCREEN::" antialiasing="::WIN_ANTIALIASING::" />\n\n').execute (context);
		
		for (key in defines.keys ()) {
			
			if (key.indexOf ("WIN_") != 0 && key.indexOf ("APP_") != 0) {
				
				switch (key) {
					
					case "target", "ANDROID_SETUP", "SWF_VERSION", "PRELOADER_NAME":
						
					
					default:
						
						if (!environment.exists (key) || environment.get (key) != defines.get (key)) {
							
							nmml += '	<set name="' + key + '" value="' + defines.get (key) + '" />\n';
							
						}
					
				}
				
			}
			
		}
		
		if (defines.keys () != null) {
			
			nmml += "\n";
			
		}
		
		for (compilerFlag in compilerFlags) {
			
			nmml += '	<haxeflag name="' + compilerFlag + '" />\n';
			
		}
		
		if (compilerFlags.length > 0) {
			
			nmml += "\n";
			
		}
		
		for (includePath in includePaths) {
			
			nmml += '	<source path="' + includePath + '" />\n';
			
		}
		
		if (includePaths.length > 0) {
			
			nmml += "\n";
			
		}
		
		for (swfLibrary in swfLibraries) {
			
			nmml += '	<library path="' + swfLibrary.sourcePath + '" rename="' + swfLibrary.targetPath + '" />\n';
			
		}
		
		if (swfLibraries.length > 0) {
			
			nmml += "\n";
			
		}
		
		for (javaPath in javaPaths) {
			
			nmml += '	<java path="' + javaPath + '" />\n';
			
		}
		
		if (javaPaths.length > 0) {
			
			nmml += "\n";
			
		}
		
		for (ndll in ndlls) {
			
			nmml += '	<ndll name="' + ndll.name + '"';
			
			if (ndll.haxelib != null && ndll.haxelib != "") {
				
				nmml += ' haxelib="' + ndll.haxelib + '"';
				
			}
			
			nmml += ' />\n';
			
		}
		
		if (ndlls.length > 0) {
			
			nmml += "\n";
			
		}
		
		for (asset in assets) {
			
			nmml += '	<assets path="' + asset.sourcePath + '" rename="' + asset.targetPath + '" name="' + asset.id + '" type="' + asset.type + '" />\n';
			
		}
		
		if (assets.length > 0) {
			
			nmml += "\n";
			
		}
		
		nmml += "</project>";
		
		Lib.println (nmml);
		
	}
	
	
	private static function error (message:String = "", e:Dynamic = null):Void {
		
		InstallTool.error (message, e);
		
	}
	
	
	private function filter (text:String, include:String = "*", exclude:String = ""):Bool {
		
		include = StringTools.replace (include, ".", "\\.");
		exclude = StringTools.replace (exclude, ".", "\\.");
		include = StringTools.replace (include, "*", ".*");
		exclude = StringTools.replace (exclude, "*", ".*");
		
		var includeFilters:Array <String> = include.split ("|");
		var excludeFilters:Array <String> = exclude.split ("|");
		
		for (filter in excludeFilters) {
			
			if (filter != "") {
				
				var regexp:EReg = new EReg ("^" + filter, "i");
				
				if (regexp.match (text)) {
					
					return false;
					
				}
				
			}
			
		}
		
		for (filter in includeFilters) {
			
			if (filter != "") {
				
				var regexp:EReg = new EReg ("^" + filter, "i");
				
				if (!regexp.match (text)) {
					
					return false;
					
				}
				
			}
			
		}
		
		return true;
		
	}
	
	
	private function findIncludeFile (base:String):String {
		
		if (base == "") {
			
			return "";
			
		}
		
		if (base.substr (0, 1) != "/" && base.substr (0, 1) != "\\") {
			
			if (base.substr (1, 1) != ":") {
				
				for (path in includePaths) {
					
					var includePath = path + "/" + base;
					
					if (FileSystem.exists (includePath)) {
						
						if (FileSystem.exists (includePath + "/include.nmml")) {
							
							return includePath + "/include.nmml";
							
						} else {
							
							return includePath;
							
						}
						
					}
					
				}
				
				return "";
				
			}
			
			if (FileSystem.exists (base)) {
				
				if (FileSystem.exists (base + "/include.nmml")) {
					
					return base + "/include.nmml";
					
				} else {
					
					return base;
					
				}
				
			}
			
		}
		
		return "";
		
	}
   
	
	private function generateContext ():Void {
		
		context = { };
		
		for (key in defines.keys ()) {
			
			Reflect.setField (context, key, defines.get (key));
			
		}
		
		var embeddedAssets = new Array <Asset> ();
		
		for (asset in assets) {
			
			if (asset.type != Asset.TYPE_TEMPLATE) {
				
				embeddedAssets.push (asset);
				
			}
			
		}
		
		Reflect.setField (context, "assets", embeddedAssets);
		Reflect.setField (context, "ndlls", ndlls);
		Reflect.setField (context, "sslCaCert", sslCaCert);
		
		if (targetFlags.exists ("xml")) {
			
			compilerFlags.push ("-xml " + defines.get ("XML_DIR") + "/types.xml");
			
		}
		
		if (compilerFlags.length == 0) {
			
			context.HAXE_FLAGS = "";
			
		} else {
			
			context.HAXE_FLAGS = "\n" + compilerFlags.join ("\n");
			
		}
		
		var appMain:String = defines.get ("APP_MAIN");
		var indexOfPeriod = appMain.lastIndexOf (".");
        
		context.APP_MAIN_PACKAGE = appMain.substr (0, indexOfPeriod + 1);
		context.APP_MAIN_CLASS = appMain.substr (indexOfPeriod + 1);
		context.HXML_PATH = templatePaths[0] + target + "/hxml/" + (debug ? "debug" : "release") + ".hxml";
		
	}
	
	
	private function getBuildNumber (increment:Bool = true):Void {
		
		if (!defines.exists ("APP_BUILD_NUMBER")) {
			
			var versionFile = Path.withoutExtension (projectFile) + ".build";
			var version:Int = 1;

         // Do not create this file if it does not already exist
         var writeFile = false;
			
			PathHelper.mkdir (buildDirectory);
			
			if (FileSystem.exists (versionFile)) {

            writeFile = true;
				
				var previousVersion = Std.parseInt (File.getBytes (versionFile).toString ());
				
				if (previousVersion != null) {
					
					version = previousVersion;
					
					if (increment) {
						
						version ++;
						
					}
					
				}
				
			}
			
			defines.set ("APP_BUILD_NUMBER", Std.string (version));
			
			if (writeFile) {
				
				try {
					
					var output = File.write (versionFile, false);
					output.writeString (Std.string (version));
					output.close ();
					
				} catch (e:Dynamic) {}
				
			}
			
		}
		
	}
	
	
	private function initializeTool ():Void {
		
		compilerFlags.push ("-D nme_install_tool");
		
		if (InstallTool.verbose)
			compilerFlags.push ("-D verbose");
		
		if (useFullClassPaths())
			compilerFlags.push("-cp " + FileSystem.fullPath(".") );
		
		if (!defines.exists ("mobile") && !defines.exists ("desktop") && !defines.exists ("web")) {
			
			switch (target) {
				
				case "android", "ios", "webos", "blackberry":
					
					defines.set ("mobile", "1");
				
				case "flash", "html5":
					
					defines.set ("web", "1");
				
				default:
					
					defines.set ("desktop", "1");
				
			}
			
		}
		
		if (targetFlags.exists ("air")) {
			
			defines.set ("air", "1");
			compilerFlags.push ("-D air");
			
		}
		
		if (targetFlags.exists ("html5")) {
			
			defines.set ("html5", "1");
			compilerFlags.push ("-D html5");
			
		}
		
		if (defines.exists ("mobile")) {
			
			setDefault ("WIN_WIDTH", "0");
			setDefault ("WIN_HEIGHT", "0");
            setDefault ("WIN_FULLSCREEN", "true");
			
		} else {
			
			setDefault ("WIN_WIDTH", "640");
			setDefault ("WIN_HEIGHT", "480");
            setDefault ("WIN_FULLSCREEN", "false");
			
		}
		
		setDefault ("WIN_ORIENTATION", "");
		setDefault ("WIN_FPS", "60");
		setDefault ("WIN_BACKGROUND", "0xffffff");
		setDefault ("WIN_HARDWARE", "true");
		
		if (defines.exists ("mac")) {
			
			setDefault ("WIN_RESIZABLE", "false");
			
		} else {
			
			setDefault ("WIN_RESIZABLE", "true");
			
		}
		
		setDefault ("WIN_BORDERLESS", "false");
		setDefault ("WIN_VSYNC", "false");
		setDefault ("WIN_ANTIALIASING", "1");
		setDefault ("APP_FILE", "MyApplication");
		setDefault ("APP_DESCRIPTION", "");
		setDefault ("APP_PACKAGE", "com.example.myapp");
		setDefault ("APP_VERSION", "1.0.0");
		setDefault ("APP_COMPANY", "Example Inc.");
		
		if (targetFlags.exists ("air")) {
			
			setDefault ("SWF_VERSION", "11.3");
			
		} else {
			
			setDefault ("SWF_VERSION", "10.1");
			
		}
		
		setDefault ("PRELOADER_NAME", "NMEPreloader");
		setDefault ("PRERENDERED_ICON", "false");
		setDefault ("ANDROID_INSTALL_LOCATION", "preferExternal");
		setDefault ("BUILD_DIR", "bin");
		setDefault ("DOCS_DIR", "docs");
		setDefault ("WIN_PARAMETERS", "{}");
		
		defines.set ("target_" + target, "1");
		defines.set (target, "1");
		defines.set ("target" , target);
		
		if (defines.exists ("armv6")) {
			
			compilerFlags.push ("-D armv6");
			
		}
		
	}
	
	
	private function isValidElement (element:Fast, section:String):Bool {
		
		if (element.x.get ("if") != null) {
			
			if (!defines.exists (element.x.get ("if"))) {
				
				return false;
				
			}
			
		}
		
		if (element.has.unless) {
			
			if (defines.exists (element.att.unless)) {
				
				return false;
				
			}
			
		}
		
		if (section != "") {
			
			if (element.name != "section") {
				
				return false;
				
			}
			
			if (!element.has.id) {
				
				return false;
				
			}
			
			if (element.att.id != section) {
				
				return false;
				
			}
			
		}
		
		return true;
		
	}
	
	
	private function parseAppElement (element:Fast):Void {
		
		for (attribute in element.x.attributes ()) {
			
			switch (attribute) {
				
				case "path":
					
					defines.set ("BUILD_DIR", substitute (element.att.path));
				
				case "min-swf-version":
					
					var version = substitute (element.att.resolve ("swf-version"));
					
					if (!defines.exists ("SWF_VERSION") || Std.parseInt (defines.get ("SWF_VERSION")) <= Std.parseInt (version)) {
						
						defines.set ("SWF_VERSION", version);
						
					}
				
				case "swf-version":
					
					defines.set ("SWF_VERSION", substitute (element.att.resolve ("swf-version")));
				
				case "preloader":
					
					defines.set ("PRELOADER_NAME", substitute (element.att.preloader));
				
				default:
					
					// if we are happy with this spec, we can tighten up this parsing a bit, later
					
					defines.set ("APP_" + StringTools.replace (attribute.toUpperCase (), "-", "_"), substitute (element.att.resolve (attribute)));
				
			}
			
		}
		
	}
	
	
	private function parseAssetsElement (element:Fast, basePath:String = "", isTemplate:Bool = false):Void {
		
		var path:String = "";
		var embed:String = "";
		var targetPath:String = "";
		var type:String = "";
		
		if (element.has.path) {
			
			path = basePath + substitute (element.att.path);
			
		}
		
		if (element.has.embed) {
			
			embed = substitute (element.att.embed);
			
		}
		
		if (element.has.rename) {
			
			targetPath = substitute (element.att.rename);
			
		} else {
			
			targetPath = path;
			
		}
		
		if (isTemplate) {
			
			type = Asset.TYPE_TEMPLATE;
			
		} else if (element.has.type) {
			
			type = substitute (element.att.type);
			
		}
		
		if (path == "" && (element.has.include || element.has.exclude || type != "" )) {
			
			error ("In order to use 'include' or 'exclude' on <asset /> nodes, you must specify also specify a 'path' attribute");
			return;
			
		} else if (!element.elements.hasNext ()) {
			
			// Empty element
			
			if (path == "") {
				
				return;
				
			}
			
			if (!FileSystem.exists (path)) {
				
				error ("Could not find asset path \"" + path + "\"");
				return;
				
			}
			
			if (!FileSystem.isDirectory (path)) {
				
				var id:String = "";
				
				if (element.has.id) {
					
					id = substitute (element.att.id);
					
				}
				
				assets.push (new Asset (path, targetPath, type, id, embed));
				
			} else {
				
				var exclude:String = ".*|cvs|thumbs.db|desktop.ini|*.hash";
				var include:String = "";
				
				if (element.has.exclude) {
					
					exclude += "|" + element.att.exclude;
					
				}
				
				if (element.has.include) {
					
					include = element.att.include;
					
				} else {
					
					switch (type) {
						
						case Asset.TYPE_IMAGE:
							
							include = "*.jpg|*.jpeg|*.png|*.gif";
						
						case Asset.TYPE_SOUND:
							
							include = "*.wav|*.ogg";
						
						case Asset.TYPE_MUSIC:
							
							include = "*.mp2|*.mp3";
						
						case Asset.TYPE_FONT:
							
							include = "*.otf|*.ttf";
						
						case Asset.TYPE_TEMPLATE:
							
							include = "*";
						
						default:
							
							include = "*";
						
					}
					
				}
				
				parseAssetsElementDirectory (path, targetPath, include, exclude, type, embed, true);
				
			}
			
		} else {
			
			if (path != "") {
				
				path += "/";
				
			}
			
			if (targetPath != "") {
				
				targetPath += "/";
				
			}
			
			for (childElement in element.elements) {
				
				if (isValidElement (childElement, "")) {
					
					var childPath:String = substitute (childElement.has.name ? childElement.att.name : childElement.att.path);
					var childTargetPath:String = childPath;
					var childEmbed:String = embed;
					var childType:String = type;
					
					if (childElement.has.rename) {
						
						childTargetPath = childElement.att.rename;
						
					}
					
					if (childElement.has.embed) {
						
						childEmbed = substitute (childElement.att.embed);
						
					}
					
					switch (childElement.name) {
						
						case Asset.TYPE_IMAGE, Asset.TYPE_SOUND, Asset.TYPE_MUSIC, Asset.TYPE_FONT, Asset.TYPE_TEMPLATE:
							
							childType = childElement.name;
						
						default:
							
							if (childElement.has.type) {
								
								childType = substitute (childElement.att.type);
								
							}
						
					}
					
					var id:String = "";
					
					if (childElement.has.id) {
						
						id = substitute (childElement.att.id);
						
					}
					else if (childElement.has.name) {
						
						id = substitute (childElement.att.name);
						
					}
					
					assets.push (new Asset (path + childPath, targetPath + childTargetPath, childType, id, childEmbed));
					
				}
				
			}
			
		}
		
	}
	
	
	private function parseAssetsElementDirectory (path:String, targetPath:String, include:String, exclude:String, type:String, embed:String, recursive:Bool):Void {
		
		var files:Array <String> = FileSystem.readDirectory (path);
		
		if (targetPath != "") {
			
			targetPath += "/";
			
		}
		
		for (file in files) {
			
			if (FileSystem.isDirectory (path + "/" + file) && recursive) {
				
				if (filter (file, "*", exclude)) {
					
					parseAssetsElementDirectory (path + "/" + file, targetPath + file, include, exclude, type, embed, true);
					
				}
				
			} else {
				
				if (filter (file, include, exclude)) {
					
					assets.push (new Asset (path + "/" + file, targetPath + file, type, "", embed));
					
				}
				
			}
			
		}
		
	}
	
	
	public function parseHXCPPConfig ():Void {
		
		var env = Sys.environment();
		// If the user has set it themselves, they must know what they are doing...
		if (env.exists("HXCPP_CONFIG"))
			return;
		
		var home = "";
		if (env.exists("HOME"))
			home = env.get("HOME");
		else if (env.exists("USERPROFILE"))
			home = env.get("USERPROFILE");
		else
		{
			Lib.println("Warning : No 'HOME' variable set - .hxcpp_config.xml might be missing.");
			return;
		}
		
		var config = home + "/.hxcpp_config.xml";
		
		if (defines.get ("HOST") == "windows") {
			
			config = config.split ("/").join ("\\");
			
		}
		
		defines.set("HXCPP_CONFIG", config);
		
		if (FileSystem.exists (config)) {
			
			var xml:Fast = null;
			
			try {
				
				xml = new Fast (Xml.parse (File.getContent (config)).firstElement ());
				
			} catch (e:Dynamic) {
				
				error ("\"" + config + "\" contains invalid XML data");
				
			}
			
			parseXML (xml, "");
			
		}
		
	}
	
	
	private function parseMetaElement (element:Fast):Void {
		
		for (attribute in element.x.attributes ()) {
			
			switch (attribute) {
				
				case "title", "description", "package", "version", "company", "company-id", "build-number":
					
					// if we're happy with this spec, we can shift to using META_TITLE, etc, in the future
					// for now we'll keep using the same defines, for compatibility
					
					defines.set ("APP_" + StringTools.replace (attribute, "-", "_").toUpperCase (), substitute (element.att.resolve (attribute)));
				
			}
			
		}
		
	}
	
	
	private function parseOutputElement (element:Fast):Void {
		
		if (element.has.name) {
			
			defines.set ("APP_FILE", substitute (element.att.name));
			
		}
		
		if (element.has.path) {
			
			defines.set ("BUILD_DIR", substitute (element.att.path));
			
		}
		
		if (element.has.resolve ("swf-version")) {
			
			defines.set ("SWF_VERSION", substitute (element.att.resolve ("swf-version")));
			
		}
		
	}
	
	
	private function parseProjectFile ():Void {
		
		var xml:Fast = null;
		
		try {
			
			xml = new Fast (Xml.parse (File.getContent (projectFile)).firstElement ());
			
		} catch (e:Dynamic) {
			
			error ("\"" + projectFile + "\" contains invalid XML data", e);
			
		}
		
		parseXML (xml, "");
		
	}
	
	
	private function parseSsl (element:Fast):Void {
		
		var id:String = element.has.id ? element.att.id : "cacert.pem";
		var path:String = element.has.path ? element.att.path : NME + "/tools/command-line/resources/cacert.pem";
		
		assets.push (new Asset (path, id, Asset.TYPE_TEXT, id, ""));
		sslCaCert = id;
		
	}
	
	
	private function parseXML (xml:Fast, section:String, extensionPath:String = ""):Void {
		
		for (element in xml.elements) {
			
			if (isValidElement (element, section)) {
				
				switch (element.name) {
					
					case "set":
						
						var value:String = "";
						
						if (element.has.value) {
							
							value = substitute (element.att.value);
							
						}
						defines.set (element.att.name, value);
					
					case "unset":
						
						defines.remove (element.att.name);
					
					case "setenv":
						
						var value:String = "";
						
						if (element.has.value) {
							
							value = substitute (element.att.value);
							
						} else {
							
							value = "1";
							
						}
						
						var name:String = element.att.name;
						
						defines.set (name, value);
						Sys.putEnv (name, value);
					
					case "error":
						
						error (substitute (element.att.value));
	
					case "echo":
						
						Lib.println (substitute (element.att.value));
					
					case "path":
						
						var value = "";
						
						if (element.has.value) {
							
							value = substitute (element.att.value);
							
						} else {
							
							value = substitute (element.att.name);
							
						}
						
						if (defines.get ("HOST") == "windows") {
							
							Sys.putEnv ("PATH", value + ";" + Sys.getEnv ("PATH"));
							
						} else {
							
							Sys.putEnv ("PATH", value + ":" + Sys.getEnv ("PATH"));
							
						}
					
					case "include":
						
						var name:String = "";
						
						if (element.has.path) {
							
							name = findIncludeFile (extensionPath + substitute (element.att.path));
							
						} else {
							
							name = findIncludeFile (extensionPath + substitute (element.att.name));
							name = findIncludeFile (extensionPath + substitute (element.att.name));
							
						}
						
						if (name != "") {
							
							var xml:Fast = new Fast (Xml.parse (File.getContent (name)).firstElement ());
							var path = Path.directory (name);
							if (useFullClassPaths ()) {
                                                        	path = FileSystem.fullPath (path);
                                                	}
							
							compilerFlags.push ("-cp " + path);
							
							if (element.has.section) {
								
								//parseXML (xml, element.att.section);
								parseXML (xml, element.att.section, path + "/");
								
							} else {
								
								//parseXML (xml, "");
								parseXML (xml, "", path + "/");
								
							}
							
						} else if (!element.has.noerror) {
							
							error ("Could not find include file \"" + name + "\"");
							
						}
					
					case "meta":
						
						parseMetaElement (element);
					
					case "app":
						
						parseAppElement (element);
					
					case "java":
						
						javaPaths.push (extensionPath + substitute (element.att.path));
					
					case "haxelib":
						
						var name:String = substitute (element.att.name);
						compilerFlags.push ("-lib " + name);
						
						var path = Utils.getHaxelib (name);
						
						if (FileSystem.exists (path + "/include.nmml")) {
							
							var xml:Fast = new Fast (Xml.parse (File.getContent (path + "/include.nmml")).firstElement ());
							parseXML (xml, "", path + "/");
							
						}
					
					case "ndll":
						
						var name:String = substitute (element.att.name);
						var haxelib:String = "";
						
						if (element.has.haxelib) {
							
							haxelib = substitute (element.att.haxelib);
							
						}
						
						if (extensionPath != "" && haxelib == "") {
							
							var ndll = new NDLL (name, "nme-extension");
							ndll.extension = extensionPath;
							ndlls.push (ndll);
							
						} else {
							
							ndlls.push (new NDLL (name, haxelib));
							
						}
					
					case "launchImage":
						
						var name:String = "";
						
						if (element.has.path) {
							
							name = substitute(element.att.path);
							
						} else {
							
							name = substitute(element.att.name);
							
						}
						
						var width:String = "";
						var height:String = "";
						
						if (element.has.width) {
							
							width = substitute (element.att.width);
							
						}
						
						if (element.has.height) {
							
							height = substitute (element.att.height);
							
						}
						
						launchImages.push (new LaunchImage(name, width, height));
					
					case "icon":
						
						var name:String = "";
						
						if (element.has.path) {
							
							name = substitute(element.att.path);
							
						} else {
							
							name = substitute(element.att.name);
							
						}
						
						var width:String = "";
						var height:String = "";
						
						if (element.has.size) {
							
							width = height = substitute (element.att.size);
							
						}
						
						if (element.has.width) {
							
							width = substitute (element.att.width);
							
						}
						
						if (element.has.height) {
							
							height = substitute (element.att.height);
							
						}
						
						icons.add (new Icon (name, width, height));
					
					case "source", "classpath":
						
						var path = "";
						
						if (element.has.path) {
							
							path = extensionPath + substitute (element.att.path);
							
						} else {
							
							path = extensionPath + substitute (element.att.name);
							
						}
						
						if (useFullClassPaths ()) {
							
							path = FileSystem.fullPath (path);
							
						}
                      
						compilerFlags.push ("-cp " + path);
					
					case "extension":
						
						// deprecated -- use <haxelib name="sqlite"/> or <include path="path/to/sqlite/include.nmml" /> instead
						
						var name:String = null;
						var path:String = null;
						
						if (element.has.haxelib) {
							
							name = substitute (element.att.haxelib);
							path = Utils.getHaxelib (name);
							
						} else {
							
							name = substitute (element.att.name);
							path = extensionPath + substitute (element.att.path);
							
						}
						
						if (name != "" && path != null) {
							
							var includePath = findIncludeFile (path + "/" + name + ".xml");
							
							if (includePath != "") {
								
								var xml:Fast = new Fast (Xml.parse (File.getContent (includePath)).firstElement ());
								
								parseXML (xml, "", path + "/");
								
							} else {
								
								var ndll = new NDLL (name, "nme-extension");
								ndll.extension = path;
								ndlls.push (ndll);
								
								if (useFullClassPaths ()) {
									
									path = FileSystem.fullPath (path);
									
								}
								
								compilerFlags.push ("-cp " + path);
								
							}
							
						}
					
					case "haxedef":
						
						compilerFlags.push("-D " + substitute (substitute (element.att.name)));
					
					case "haxeflag", "compilerflag":
						
						var flag = substitute (element.att.name);
						
						if (element.has.value) {
							
							flag += " " + substitute (element.att.value);
							
						}
						
						compilerFlags.push (substitute (flag));
					
					case "window":
						
						parseWindowElement (element);
					
					case "assets":
						
						parseAssetsElement (element, extensionPath);
					
					case "library", "swf":
						
						var path = extensionPath + substitute (element.att.path);
						var targetPath = "libraries/" + Path.withoutDirectory (path);
						
						var asset = new Asset (path, targetPath, Asset.TYPE_BINARY, "", "");
						
						assets.push (asset);
						
						compilerFlags.remove ("-lib swf");
						compilerFlags.push ("-lib swf");
						
						swfLibraries.push (asset);
					
					case "ssl":
						
						if (wantSslCertificate())
						   parseSsl (element);
					
					case "template":
						
						parseAssetsElement (element, extensionPath, true);
					
					case "preloader":
						
						// deprecated
						
						defines.set ("PRELOADER_NAME", substitute (element.att.name));
					
					case "output":
						
						parseOutputElement (element);
					
					case "section":
						
						parseXML (element, "");
					
					case "certificate":
						
						defines.set ("KEY_STORE", substitute (element.att.path));
						
						if (element.has.type) {
							
							defines.set ("KEY_STORE_TYPE", substitute (element.att.type));
							
						}
						
						if (element.has.password) {
							
							defines.set ("KEY_STORE_PASSWORD", substitute (element.att.password));
							
							
						}
						
						if (element.has.alias) {
							
							defines.set ("KEY_STORE_ALIAS", substitute (element.att.alias));
							
						}
						
						if (element.has.resolve ("alias-password")) {
							
							defines.set ("KEY_STORE_ALIAS_PASSWORD", substitute (element.att.resolve ("alias-password")));
							
						} else if (element.has.alias_password) {
							
							defines.set ("KEY_STORE_ALIAS_PASSWORD", substitute (element.att.alias_password));
							
						}
					
					case "dependency":
						
						dependencyNames.push (substitute (element.att.name));
	
					
					case "ios":
						
						if (element.has.deployment)
                  {
                     var deploy = substitute(element.att.deployment);
                     if (deploy>iosDeployment)
                        iosDeployment = deploy;
                  }
						if (element.has.binaries)
                     iosBinaries = substitute(element.att.binaries);
						if (element.has.devices)
                     iosDevices = substitute(element.att.devices);
						if (element.has.compiler)
                     iosCompiler = substitute(element.att.compiler);
					
				}
				
			}
			
		}
		
	}	
	
	
	private function parseWindowElement (element:Fast):Void {
		
		for (attribute in element.x.attributes ()) {
			
			defines.set ("WIN_" + attribute.toUpperCase (), substitute (element.att.resolve (attribute)));
			
		}
		
	}
	
	
	private function print (message:String):Void {
		
		if (InstallTool.verbose) {
			
			Lib.println (message);
			
		}
		
	}
	
	
	private function setDefault (name:String, value:String):Void {
		if (!defines.exists (name)) {
			
			defines.set (name, value);
		
			
		}
		
	}
	
	
	private function substitute (string:String):String {
		
		var newString:String = string;
		
		while (varMatch.match (newString)) {
			
			newString = defines.get (varMatch.matched (1));
			
			if (newString == null) {
				
				newString = "";
				
			}
			
			newString = varMatch.matchedLeft () + newString + varMatch.matchedRight ();
			
		}
		
		return newString;
		
	}
	
	
	private function wantSslCertificate ():Bool {
		
		return true;
		
	}
	
	
}
