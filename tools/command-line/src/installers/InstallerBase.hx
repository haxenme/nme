package installers;


import data.Asset;
import data.Icon;
import data.Icons;
import data.NDLL;
import haxe.Stack;
import haxe.Template;
import haxe.xml.Fast;
import neko.io.File;
import neko.io.FileOutput;
import neko.io.Path;
import neko.FileSystem;
import neko.Lib;
import neko.Sys;


class InstallerBase {
	
	
	public var defines:Hash <String>;
	
	private var assets:Array <Asset>;
	private var buildDirectory:String;
	private var command:String;
	private var compilerFlags:Array <String>;
	private var context:Dynamic;
	private var debug:Bool;
	private var icons:Icons;
	private var includePaths:Array <String>;
	private var javaPaths:Array <String>;
	private var ndlls:Array <NDLL>;
	private var allFiles:Array <String>;
	private var NME:String;
	private var projectFile:String;
	private var target:String;
	private var sslCaCert:String;
	private var targetFlags:Hash <String>;
	
	private static var varMatch = new EReg("\\${(.*?)}", "");

	
	public function new () {
		
		assets = new Array <Asset> ();
		compilerFlags = new Array <String> ();
		defines = new Hash <String> ();
		icons = new Icons ();
		includePaths = new Array <String> ();
		javaPaths = new Array <String> ();
		allFiles = new Array <String> ();
		ndlls = new Array <NDLL> ();
      sslCaCert = "";
		
	}
	
	
	public function create (inNME:String, command:String, defines:Hash <String>, includePaths:Array <String>, projectFile:String, target:String, targetFlags:Hash <String>, debug:Bool):Void {
		
		NME = inNME;
		this.command = command;
		this.defines = defines;
		this.includePaths = includePaths;
		this.projectFile = projectFile;
		this.target = target;
		this.targetFlags = targetFlags;
		this.debug = debug;
		
		initializeTool ();
		parseHXCPPConfig ();
		parseProjectFile ();
		
		if (defines.get ("APP_PACKAGE").split (".").length < 3) {
			
			error ("Your application package must have at least three segments, like <app package=\"com.example.myapp\" />");
			
		}
		
		if (command == "trace") {
			
			InstallTool.traceEnabled = true;
			
		}
		
		// Strip off 0x ....
		setDefault ("WIN_FLASHBACKGROUND", defines.get ("WIN_BACKGROUND").substr (2));
		setDefault ("APP_VERSION_SHORT", defines.get ("APP_VERSION").substr (2));
		setDefault ("XML_DIR", defines.get ("BUILD_DIR") + "/" + target);
		setDefault ("KEY_STORE_ALIAS_PASSWORD", defines.get ("KEY_STORE_PASSWORD"));
		
		if (defines.exists ("KEY_STORE")) {
			
			setDefault ("KEY_STORE_ALIAS", Path.withoutExtension (Path.withoutDirectory (defines.get ("KEY_STORE"))));
			
		}
		
		if (defines.exists ("NME_64")) {
			
			compilerFlags.push ("-D HXCPP_M64");
			
		}
		
		buildDirectory = defines.get ("BUILD_DIR");
		
		onCreate ();
		generateContext ();
		
		if (defines.get ("SHOW_CONSOLE") != "true") {
			
			Sys.putEnv ("no_console", "1");
			
		}
		
		// Commands:
		//
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
		
		var validCommands = [ "update", "build", "test", "run", "rerun", "trace", "uninstall", "document", "display" ];
		
		if (!validCommands.remove (command)) {
			
			error ("Command \"" + command + "\" has not been implemented");
			
		}
		
	}
	
	
	function onCreate ():Void { }
	function useFullClassPaths () { return false; }
	
	function update () { error ("Update not implemented."); }
	function build () { error ("Build not implemented."); }
	function run () { error ("Run not implemented."); }
	function updateDevice () { /* Not required on all platforms. */ }
	function install () { error ("Install not implemented."); }
	function traceMessages () { /* Not required on all platforms. */ }
	function uninstall () { error ("Uninstall not implemented."); }
	
	
	function addFile (file:String):Bool {
		
		if (file != null && file != "") {
			
			allFiles.push (file);
			print("Adding file to installer: " + file);
			
			return true;
			
		}
		
		return false;
		
	}
	
	
	private function copyIfNewer (source:String, destination:String) {
      
		allFiles.push (destination);
		
		if (!isNewer (source, destination)) {
			
			return;
			
		}
		
		print ("Copy " + source + " to " + destination);
		
		mkdir (Path.directory (destination));
		File.copy (source, destination);
		
	}
	
	
	private function copyFile (source:String, destination:String, process:Bool = true) {
		
		var extension:String = Path.extension (source);
		
		if (process &&
            (extension == "xml" ||
             extension == "java" ||
             extension == "hx" ||
             extension == "hxml" ||
			 extension == "html" || 
             extension == "ini" ||
             extension == "gpe" ||
             extension == "pbxproj" ||
             extension == "plist" ||
             extension == "json" ||
             extension == "cpp" ||
             extension == "properties")) {
			
			print("process " + source + " " + destination);
			
			var fileContents:String = File.getContent (source);
			var template:Template = new Template (fileContents);
			var result:String = template.execute (context);
			var fileOutput:FileOutput = File.write (destination, true);
			fileOutput.writeString (result);
			fileOutput.close ();
			
		} else {
			
			copyIfNewer (source, destination);
			
		}
		
	}
	
	
	private function displayHXML ():Void {
		
		var templateFile = context.HXML_PATH;
		
		var fileContents:String = File.getContent (templateFile);
		var template:Template = new Template (fileContents);
		var result:String = template.execute (context);
		
		Lib.println (result);
		
	}
	
	
	private function displayNMML ():Void {
		
		var nmml = '<?xml version="1.0" encoding="utf-8"?>\n<project>\n\n';
		var environment = Sys.environment ();
		
		nmml += new Template ('	<app title="::APP_TITLE::" description="::APP_DESCRIPTION::" package="::APP_PACKAGE::" version="::APP_VERSION::" company="::APP_COMPANY::" />\n\n').execute (context);
		
		nmml += new Template ('	<window width="::WIN_WIDTH::" height="::WIN_HEIGHT::" orientation="::WIN_ORIENTATION::" fps="::WIN_FPS::" background="::WIN_BACKGROUND::" borderless="::WIN_BORDERLESS::" fullscreen="::WIN_FULLSCREEN::" antialiasing="::WIN_ANTIALIASING::" />\n\n').execute (context);
		
		nmml += '	<output name="' + defines.get ("APP_FILE") + '" path="' + buildDirectory + '" swf-version="' + defines.get ("SWF_VERSION") + '" />\n\n';
		
		for (key in defines.keys ()) {
			
			if (key.indexOf ("WIN_") != 0 && key.indexOf ("APP_") != 0) {
				
				if (!environment.exists (key) || environment.get (key) != defines.get (key)) {
					
					nmml += '	<set name="' + key + '" value="' + defines.get (key) + '" />\n';
					
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
		context.HXML_PATH = NME + "/tools/command-line/" + target + "/hxml/" + (debug ? "debug" : "release") + ".hxml";
		
	}
	
	
	private function initializeTool ():Void {
		
		compilerFlags.push ("-D nme_install_tool");
      if (InstallTool.verbose)
		   compilerFlags.push ("-D verbose");


	   if (useFullClassPaths())
			compilerFlags.push("-cp " + FileSystem.fullPath(".") );
	
		
		setDefault ("WIN_WIDTH", "640");
		setDefault ("WIN_HEIGHT", "480");
		setDefault ("WIN_ORIENTATION", "");
		setDefault ("WIN_FPS", "60");
		setDefault ("WIN_BACKGROUND", "0xffffff");
		setDefault ("WIN_HARDWARE", "true");
		setDefault ("WIN_RESIZEABLE", "true");
		setDefault ("WIN_BORDERLESS", "false");
		setDefault ("WIN_FULLSCREEN", "false");
		setDefault ("WIN_ANTIALIASING", "1");
		setDefault ("APP_FILE", "MyApplication");
		setDefault ("APP_DESCRIPTION", "");
		setDefault ("APP_PACKAGE", "com.example.myapp");
		setDefault ("APP_VERSION", "1.0.0");
		setDefault ("APP_COMPANY", "Example Inc.");
		setDefault ("SWF_VERSION", "10");
		setDefault ("PRELOADER_NAME", "NMEPreloader");
		setDefault ("PRERENDERED_ICON", "false");
		setDefault ("ANDROID_INSTALL_LOCATION", "preferExternal");
		setDefault ("BUILD_DIR", "bin");
		setDefault ("DOCS_DIR", "docs");
		setDefault ("SHOW_CONSOLE", "false");
		defines.set ("target_" + target, "1");
		defines.set (target, "1");
		defines.set ("target" , target);
		
	}
	
	
	private static function isNewer (source:String, destination:String):Bool {
		
		if (source == null || !FileSystem.exists (source)) {
			
			error ("Source path \"" + source + "\" does not exist");
			return false;
			
		}
		
		if (FileSystem.exists (destination)) {
			
			if (FileSystem.stat (source).mtime.getTime () < FileSystem.stat (destination).mtime.getTime ()) {
				
				return false;
				
			}
			
		}
		
		return true;
		
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
	
	
	private function mkdir (directory:String):Void {
		
		InstallTool.mkdir (directory);
		
	}
	
	
	private function parseAppElement (element:Fast):Void {
		
		for (attribute in element.x.attributes ()) {
			
			defines.set ("APP_" + attribute.toUpperCase (), substitute (element.att.resolve (attribute)));
			
		}
		
	}

	private function wantSslCertificate ():Bool {
      return true;
   }
	
	private function parseSsl (element:Fast):Void {

		var id:String = element.has.id ? element.att.id : "cacert.pem";

		var path:String = element.has.path ? element.att.path : NME + "/tools/command-line/resources/cacert.pem";


		assets.push (new Asset (path, id, Asset.TYPE_ASSET, id, ""));

      sslCaCert = id;
   }
	
	private function parseAssetsElement (element:Fast, basePath:String = "", isTemplate:Bool = false):Void {
		
		var path:String = "";
		var embed:String = "";
		var rename:String = "";
		var type:String = "";
		
		if (element.has.path) {
			
			path = basePath + substitute (element.att.path);
			
		}
		
		if (element.has.embed) {
			
			embed = substitute (element.att.embed);
			
		}
		
		if (element.has.rename) {
			
			rename = substitute (element.att.rename);
			
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
			
			if (path == "")
				return;
			
			if (path == "" || !FileSystem.exists (path)) {
				
				error ("Could not find asset path \"" + path + "\"");
				return;
				
			}
			
			if (!FileSystem.isDirectory (path)) {
				
				var id:String = "";
				
				if (element.has.id) {
					
					id = substitute (element.att.id);
					
				}
				
				assets.push (new Asset (path, rename, type, id, embed));
				
			} else {
				
				var exclude:String = ".*|cvs|thumbs.db|desktop.ini";
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
							
							return;
						
					}
					
				}
				
				parseAssetsElementDirectory (path, rename, include, exclude, type, embed, true);
				
			}
			
		} else {
			
			if (path != "") {
				
				path += "/";
				
			}
			
			if (rename != "") {
				
				rename += "/";
				
			}
			
			for (childElement in element.elements) {
				
				var childPath:String = substitute (childElement.has.name ? childElement.att.name : childElement.att.path);
				var childRename:String = childPath;
				var childEmbed:String = embed;
				var childType:String = type;
				
				if (childElement.has.rename) {
					
					childRename = childElement.att.rename;
					
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
				
				assets.push (new Asset (path + childPath, rename + childRename, childType, id, childEmbed));
				
			}
			
		}
		
	}
	
	
	private function parseAssetsElementDirectory (path:String, rename:String, include:String, exclude:String, type:String, embed:String, recursive:Bool):Void {
		
		if (rename == "")
			rename = path;
		
		var files:Array <String> = FileSystem.readDirectory (path);
		
		for (file in files) {
			
			if (FileSystem.isDirectory (path + "/" + file) && recursive) {
				
				if (filter (file, "*", exclude)) {
					
					parseAssetsElementDirectory (path + "/" + file, rename + "/" + file, include, exclude, type, embed, true);
					
				}
				
			} else {
				
				if (filter (file, include, exclude)) {
					
					assets.push (new Asset (path + "/" + file, rename + "/" + file, type, "", embed));
					
				}
				
			}
			
		}
		
	}
	
	
	public function parseHXCPPConfig ():Void {
		
		var env = neko.Sys.environment();
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
			neko.Lib.println("Warning : No 'HOME' variable set - .hxcpp_config.xml might be missing.");
			return;
		}
		
		var config = home + "/.hxcpp_config.xml";
		
		if (defines.get ("HOST") == "windows") {
			
			config = config.split ("/").join ("\\");
			
		}
		
		defines.set("HXCPP_CONFIG", config);
		
		if (neko.FileSystem.exists (config)) {
			
			var xml:Fast = null;
			
			try {
				
				xml = new Fast (Xml.parse (File.getContent (config)).firstElement ());
				
			} catch (e:Dynamic) {
				
				error ("\"" + config + "\" contains invalid XML data");
				
			}
			
			parseXML (xml, "");
			
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
						
						var name:String = element.att.name;
						var value:String = substitute (element.att.value);
						
						defines.set (name, value);
						Sys.putEnv (name, value);
					
					case "error":
						
						error (substitute (element.att.value));
					
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
					
					case "app":
						
						parseAppElement (element);
					
					case "java":
						
						javaPaths.push (extensionPath + substitute (element.att.path));
					
					case "haxelib":
						
						var name:String = substitute (element.att.name);
						compilerFlags.push ("-lib " + name);
						
						var path = Utils.getHaxelib (name) + "/include.nmml";
						
						if (FileSystem.exists (path)) {
							
							var xml:Fast = new Fast (Xml.parse (File.getContent (path)).firstElement ());
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
						
						compilerFlags.push(substitute (substitute (element.att.name)));
					
					case "window":
						
						parseWindowElement (element);
					
					case "assets":
						
						parseAssetsElement (element, extensionPath);
					
					case "ssl":
						
                  if (wantSslCertificate())
						   parseSsl (element);
					
					case "template":
						
						parseAssetsElement (element, extensionPath, true);
					
					case "preloader":
						
						defines.set ("PRELOADER_NAME", substitute (element.att.name));
					
					case "output":
						
						parseOutputElement (element);
					
					case "section":
						
						parseXML (element, "");
					
					case "certificate":
						
						defines.set ("KEY_STORE", substitute (element.att.path));
						
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
	
	
	public function recursiveCopy (source:String, destination:String, process:Bool = true) {
		
		mkdir (destination);
		var files = FileSystem.readDirectory (source);
		
		for (file in files) {
			
			if (file.substr (0, 1) != ".") {
				
				var itemDestination:String = destination + "/" + file;
				var itemSource:String = source + "/" + file;
				
				if (FileSystem.isDirectory (itemSource)) {
					
					recursiveCopy (itemSource, itemDestination, process);
					
				} else {
					
					copyFile (itemSource, itemDestination, process);
					
				}
				
			}
			
		}
		
	}
	
	
	private function runCommand (path:String, command:String, args:Array <String>):Void {
		
		try {
			
			if (path != "" && !FileSystem.exists (FileSystem.fullPath (new Path (path).dir))) {
				
				error ("The specified target path \"" + path + "\" does not exist");
				
			}
			
			InstallTool.runCommand (path, command, args);
			
		} catch (e:Dynamic) {
			
			error ("", e);
			
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
	
	
}
