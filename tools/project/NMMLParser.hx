package;


import format.xfl.dom.DOMBitmapItem;
import format.XFL;
import haxe.io.Path;
import haxe.xml.Fast;
import sys.io.File;
import sys.FileSystem;
import NMEProject;
import PlatformConfig;


class NMMLParser extends NMEProject {
	
	
	public var localDefines:Hash <String>;
	public var includePaths:Array <String>;
	
	private static var varMatch = new EReg("\\${(.*?)}", "");
	
	
	public function new (path:String = "", defines:Hash <String> = null, includePaths:Array <String> = null, useExtensionPath:Bool = false) {
		
		super ();
		
		if (defines != null) {
			
			localDefines = defines;
			
		} else {
			
			localDefines = new Hash <String> ();
			
		}
		
		if (includePaths != null) {
			
			this.includePaths = includePaths;
			
		} else {
			
			this.includePaths = new Array <String> ();
			
		}
		
		initialize ();
		
		if (path != "") {
			
			process (path, useExtensionPath);
			
		}
		
	}
	
	
	private function initialize ():Void {
		
		switch (platformType) {
			
			case MOBILE:
				
				localDefines.set ("mobile", "1");
			
			case DESKTOP:
				
				localDefines.set ("desktop", "1");
			
			case WEB:
				
				localDefines.set ("web", "1");
			
		}
		
		localDefines.set (Type.enumConstructor (target).toLowerCase (), "1");
		
	}
	
	
	private function isValidElement (element:Fast, section:String):Bool {
		
		if (element.x.get ("if") != null) {
			
			var value = element.x.get ("if");
			var optionalDefines = value.split ("||");
			
			for (optional in optionalDefines) {
				
				var requiredDefines = optional.split (" ");
				var match = true;
				
				for (required in requiredDefines) {
					
					var check = StringTools.trim (required);
					
					if (check != "" && !localDefines.exists (check)) {
						
						match = false;
						
					}
					
				}
				
				if (match) {
					
					return true;
					
				}
				
			}
			
			return false;
			
		}
		
		if (element.has.unless) {
			
			var value = element.att.unless;
			var optionalDefines = value.split ("||");
			
			for (optional in optionalDefines) {
				
				var requiredDefines = optional.split (" ");
				var match = true;
				
				for (required in requiredDefines) {
					
					var check = StringTools.trim (required);
					
					if (check != "" && !localDefines.exists (check)) {
						
						match = false;
						
					}
					
				}
				
				if (match) {
					
					return false;
					
				}
				
			}
			
			return true;
			
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
				
			}
			
		}
		
		if (FileSystem.exists (base)) {
			
			if (FileSystem.exists (base + "/include.nmml")) {
				
				return base + "/include.nmml";
				
			} else {
				
				return base;
				
			}
			
		}
		
		return "";
		
	}
	
	
	private function formatAttributeName (name:String):String {
		
		var segments = name.toLowerCase ().split ("-");
		
		for (i in 1...segments.length) {
			
			segments[i] = segments[i].substr (0, 1).toUpperCase () + segments[i].substr (1);
			
		}
		
		return segments.join ("");
		
	}
	
	
	private function parseAppElement (element:Fast):Void {
		
		for (attribute in element.x.attributes ()) {
			
			switch (attribute) {
				
				case "path":
					
					//defines.set ("BUILD_DIR", substitute (element.att.path));
					app.path = substitute (element.att.path);
				
				case "min-swf-version":
					
					var version = substitute (element.att.resolve ("swf-version"));
					
					/*if (!defines.exists ("SWF_VERSION") || Std.parseInt (defines.get ("SWF_VERSION")) <= Std.parseInt (version)) {
						
						defines.set ("SWF_VERSION", version);
						
					}*/
					
					app.minimumSWFVersion = version;
				
				case "swf-version":
					
					//defines.set ("SWF_VERSION", substitute (element.att.resolve ("swf-version")));
					app.swfVersion = substitute (element.att.resolve ("swf-version"));
				
				case "preloader":
					
					//defines.set ("PRELOADER_NAME", substitute (element.att.preloader));
					app.preloader = substitute (element.att.preloader);
				
				default:
					
					// if we are happy with this spec, we can tighten up this parsing a bit, later
					
					//defines.set ("APP_" + StringTools.replace (attribute.toUpperCase (), "-", "_"), substitute (element.att.resolve (attribute)));
					
					var name = formatAttributeName (attribute);
					var value = substitute (element.att.resolve (attribute));
					
					if (attribute == "package") {
						
						name = "packageName";
						
					}
					
					if (Reflect.hasField (app, name)) {
						
						Reflect.setField (app, name, value);
						
					} else if (Reflect.hasField (meta, name)) {
						
						Reflect.setField (meta, name, value);
						
					}
				
			}
			
		}
		
	}
	
	
	private function parseAssetsElement (element:Fast, basePath:String = "", isTemplate:Bool = false):Void {
		
		var path = "";
		var embed = "";
		var targetPath = "";
		var type = null;
		
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
			
			type = AssetType.TEMPLATE;
			
		} else if (element.has.type) {
			
			type = Reflect.field (AssetType, substitute (element.att.type).toUpperCase ());
			
		}
		
		if (path == "" && (element.has.include || element.has.exclude || type != null )) {
			
			LogHelper.error ("In order to use 'include' or 'exclude' on <asset /> nodes, you must specify also specify a 'path' attribute");
			return;
			
		} else if (!element.elements.hasNext ()) {
			
			// Empty element
			
			if (path == "") {
				
				return;
				
			}
			
			if (!FileSystem.exists (path)) {
				
				LogHelper.error ("Could not find asset path \"" + path + "\"");
				return;
				
			}
			
			if (!FileSystem.isDirectory (path)) {
				
				var id = "";
				
				if (element.has.id) {
					
					id = substitute (element.att.id);
					
				}
				
				//assets.push (new Asset (path, targetPath, type, id, embed));
				var asset = new Asset (path, targetPath, type);
				asset.id = id;
				
				assets.push (asset);
				
			} else {
				
				var exclude = ".*|cvs|thumbs.db|desktop.ini|*.hash";
				var include = "";
				
				if (element.has.exclude) {
					
					exclude += "|" + element.att.exclude;
					
				}
				
				if (element.has.include) {
					
					include = element.att.include;
					
				} else {
					
					if (type == null) {
						
						include = "*";
						
					} else {
						
						switch (type) {
							
							case IMAGE:
								
								include = "*.jpg|*.jpeg|*.png|*.gif";
							
							case SOUND:
								
								include = "*.wav|*.ogg";
							
							case MUSIC:
								
								include = "*.mp2|*.mp3";
							
							case FONT:
								
								include = "*.otf|*.ttf";
							
							case TEMPLATE:
								
								include = "*";
							
							default:
								
								include = "*";
							
						}
						
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
					
					var childPath = substitute (childElement.has.name ? childElement.att.name : childElement.att.path);
					var childTargetPath = childPath;
					var childEmbed = embed;
					var childType = type;
					
					if (childElement.has.rename) {
						
						childTargetPath = childElement.att.rename;
						
					}
					
					if (childElement.has.embed) {
						
						childEmbed = substitute (childElement.att.embed);
						
					}
					
					switch (childElement.name) {
						
						case "image", "sound", "music", "font", "template":
							
							childType = Reflect.field (AssetType, childElement.name.toUpperCase ());
						
						default:
							
							if (childElement.has.type) {
								
								childType = Reflect.field (AssetType, childElement.att.type.toUpperCase ());
								
							}
						
					}
					
					var id = "";
					
					if (childElement.has.id) {
						
						id = substitute (childElement.att.id);
						
					}
					else if (childElement.has.name) {
						
						id = substitute (childElement.att.name);
						
					}
					
					//assets.push (new Asset (path + childPath, targetPath + childTargetPath, childType, id, childEmbed));
					var asset = new Asset (path + childPath, targetPath + childTargetPath, childType);
					asset.id = id;
					
					assets.push (asset);
					
				}
				
			}
			
		}
		
	}
	
	
	private function parseAssetsElementDirectory (path:String, targetPath:String, include:String, exclude:String, type:AssetType, embed:String, recursive:Bool):Void {
		
		var files = FileSystem.readDirectory (path);
		
		if (targetPath != "") {
			
			targetPath += "/";
			
		}
		
		for (file in files) {
			
			if (FileSystem.isDirectory (path + "/" + file) && recursive) {
				
				if (filter (file, [ "*" ], exclude.split ("|"))) {
					
					parseAssetsElementDirectory (path + "/" + file, targetPath + file, include, exclude, type, embed, true);
					
				}
				
			} else {
				
				if (filter (file, include.split ("|"), exclude.split ("|"))) {
					
					//assets.push (new Asset (path + "/" + file, targetPath + file, type, "", embed));
					assets.push (new Asset (path + "/" + file, targetPath + file, type));
					
				}
				
			}
			
		}
		
	}
	
	
	private function parseMetaElement (element:Fast):Void {
		
		for (attribute in element.x.attributes ()) {
			
			switch (attribute) {
				
				case "title", "description", "package", "version", "company", "company-id", "build-number":
					
					var value = substitute (element.att.resolve (attribute));
					
					localDefines.set ("APP_" + StringTools.replace (attribute, "-", "_").toUpperCase (), value);
					
					var name = formatAttributeName (attribute);
					
					if (attribute == "package") {
						
						name = "packageName";
						
					}
					
					if (Reflect.hasField (meta, name)) {
						
						Reflect.setField (meta, name, value);
						
					}
				
			}
			
		}
		
	}
	
	
	private function parseOutputElement (element:Fast):Void {
		
		if (element.has.name) {
			
			app.file = substitute (element.att.name);
			//defines.set ("APP_FILE", substitute (element.att.name));
			
		}
		
		if (element.has.path) {
			
			app.path = substitute (element.att.path);
			//defines.set ("BUILD_DIR", substitute (element.att.path));
			
		}
		
		if (element.has.resolve ("swf-version")) {
			
			app.swfVersion = substitute (element.att.resolve ("swf-version"));
			//defines.set ("SWF_VERSION", substitute (element.att.resolve ("swf-version")));
			
		}
		
	}
	
	
	private function parseXML (xml:Fast, section:String, extensionPath:String = ""):Void {
		
		for (element in xml.elements) {
			
			if (isValidElement (element, section)) {
				
				switch (element.name) {
					
					case "set":
						
						var name = element.att.name;
						var value = "";
						
						if (element.has.value) {
							
							value = substitute (element.att.value);
							
						}
						
						localDefines.set (name, value);
						environment.set (name, value);
					
					case "unset":
						
						localDefines.remove (element.att.name);
						environment.remove (element.att.name);
					
					case "setenv":
						
						var value = "";
						
						if (element.has.value) {
							
							value = substitute (element.att.value);
							
						} else {
							
							value = "1";
							
						}
						
						var name = element.att.name;
						
						localDefines.set (name, value);
						environment.set (name, value);
						setenv (name, value);
					
					case "error":
						
						LogHelper.error (substitute (element.att.value));
	
					case "echo":
						
						Sys.println (substitute (element.att.value));
					
					case "path":
						
						var value = "";
						
						if (element.has.value) {
							
							value = substitute (element.att.value);
							
						} else {
							
							value = substitute (element.att.name);
							
						}
						
						/*if (defines.get ("HOST") == "windows") {
							
							Sys.putEnv ("PATH", value + ";" + Sys.getEnv ("PATH"));
							
						} else {
							
							Sys.putEnv ("PATH", value + ":" + Sys.getEnv ("PATH"));
							
						}*/
						
						path (value);
					
					case "include":
						
						var path = "";
						
						if (element.has.path) {
							
							var subPath = substitute (element.att.path);
							if (subPath == "") subPath = element.att.path;
							path = findIncludeFile (PathHelper.combine (extensionPath, subPath));
							
						} else {
							
							path = findIncludeFile (PathHelper.combine (extensionPath, substitute (element.att.name)));
							
						}
						
						if (path != null && path != "" && FileSystem.exists (path)) {
							
							var includeProject = new NMMLParser (path);
							includeProject.sources.push (Path.directory (path));
							
							merge (includeProject);
							
						} else if (!element.has.noerror) {
							
							LogHelper.error ("Could not find include file \"" + path + "\"");
							
						}
					
					case "meta":
						
						parseMetaElement (element);
					
					case "app":
						
						parseAppElement (element);
					
					case "java":
						
						javaPaths.push (PathHelper.combine (extensionPath, substitute (element.att.path)));
					
					case "haxelib":
						
						/*var name:String = substitute (element.att.name);
						compilerFlags.push ("-lib " + name);
						
						var path = Utils.getHaxelib (name);
						
						if (FileSystem.exists (path + "/include.nmml")) {
							
							var xml:Fast = new Fast (Xml.parse (File.getContent (path + "/include.nmml")).firstElement ());
							parseXML (xml, "", path + "/");
							
						}*/
						
						var name = substitute (element.att.name);
						var path = PathHelper.getHaxelib (name);
						
						if (FileSystem.exists (path + "/include.nmml")) {
							
							var includeProject = new NMMLParser (path + "/include.nmml");
							
							for (ndll in includeProject.ndlls) {
								
								if (ndll.haxelib == "") {
									
									ndll.haxelib = name;
									
								}
								
							}
							
							includeProject.sources.push (path);
							
							merge (includeProject);
							
						}
						
						haxelibs.push (name);
					
					case "ndll":
						
						/*var name:String = substitute (element.att.name);
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
							
						}*/
						
						var name = substitute (element.att.name);
						var haxelib = "";
						
						if (element.has.haxelib) {
							
							haxelib = substitute (element.att.haxelib);
							
						}
						
						if (haxelib == "" && (name == "std" || name == "regexp" || name == "zlib")) {
							
							haxelib = "hxcpp";
							
						}
						
						var ndll = new NDLL (name, haxelib);
						ndll.extensionPath = extensionPath;
						
						ndlls.push (ndll);
					
					case "launchImage":
						
						/*var name:String = "";
						
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
						
						launchImages.push (new LaunchImage(name, width, height));*/
						
						
						var name:String = "";
						
						if (element.has.path) {
							
							name = substitute(element.att.path);
							
						} else {
							
							name = substitute(element.att.name);
							
						}
						
						var splashScreen = new SplashScreen (name);
						
						if (element.has.width) {
							
							splashScreen.width = Std.parseInt (substitute (element.att.width));
							
						}
						
						if (element.has.height) {
							
							splashScreen.height = Std.parseInt (substitute (element.att.height));
							
						}
						
						splashScreens.push (splashScreen);
					
					case "icon":
						
						/*var name:String = "";
						
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
						
						icons.add (new Icon (name, width, height));*/
						
						var name = "";
						
						if (element.has.path) {
							
							name = substitute(element.att.path);
							
						} else {
							
							name = substitute(element.att.name);
							
						}
						
						var icon = new Icon (name);
						
						if (element.has.size) {
							
							icon.size = icon.width = icon.height = Std.parseInt (substitute (element.att.size));
							
						}
						
						if (element.has.width) {
							
							icon.width = Std.parseInt (substitute (element.att.width));
							
						}
						
						if (element.has.height) {
							
							icon.height = Std.parseInt (substitute (element.att.height));
							
						}
						
						icons.push (icon);
					
					case "source", "classpath":
						
						var path = "";
						
						if (element.has.path) {
							
							path = PathHelper.combine (extensionPath, substitute (element.att.path));
							
						} else {
							
							path = PathHelper.combine (extensionPath, substitute (element.att.name));
							
						}
						
						/*if (useFullClassPaths ()) {
							
							path = FileSystem.fullPath (path);
							
						}*/
                      
						//compilerFlags.push ("-cp " + path);
						
						sources.push (path);
					
					case "extension":
						
						// deprecated -- use <haxelib name="sqlite"/> or <include path="path/to/sqlite/include.nmml" /> instead
						
						/*var name:String = null;
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
							
						}*/
					
					case "haxedef":
						
						//compilerFlags.push("-D " + substitute (substitute (element.att.name)));
						haxedefs.push (substitute (substitute (element.att.name)));
					
					case "haxeflag", "compilerflag":
						
						var flag = substitute (element.att.name);
						
						if (element.has.value) {
							
							flag += " " + substitute (element.att.value);
							
						}
						
						//compilerFlags.push (substitute (flag));
						haxeflags.push (substitute (flag));
					
					case "window":
						
						parseWindowElement (element);
					
					case "assets":
						
						parseAssetsElement (element, extensionPath);
					
					case "library", "swf":
						
						var path = PathHelper.combine (extensionPath, substitute (element.att.path));
						var name = "";
						
						if (element.has.name) {
							
							name = element.att.name;
							
						}
						
						if (element.has.id) {
							
							name = element.att.id;
							
						}
						
						libraries.push (new Library (path, name));
					
					case "ssl":
						
						//if (wantSslCertificate())
						   //parseSsl (element);
					
					case "template":
						
						parseAssetsElement (element, extensionPath, true);
					
					case "templatePath":
						
						templatePaths.push (substitute(element.att.name));
					
					case "preloader":
						
						// deprecated
						
						app.preloader = substitute (element.att.name);
						//defines.set ("PRELOADER_NAME", substitute (element.att.name));
					
					case "output":
						
						parseOutputElement (element);
					
					case "section":
						
						parseXML (element, "");
					
					case "certificate":
						
						/*defines.set ("KEY_STORE", substitute (element.att.path));
						
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
							
						}*/
						
						certificate = new Keystore (substitute (element.att.path));
						
						if (element.has.type) {
							
							certificate.type = substitute (element.att.type);
							
						}
						
						if (element.has.password) {
							
							certificate.password = substitute (element.att.password);
							
						}
						
						if (element.has.alias) {
							
							certificate.alias = substitute (element.att.alias);
							
						}
						
						if (element.has.resolve ("alias-password")) {
							
							certificate.aliasPassword = substitute (element.att.resolve ("alias-password"));
							
						} else if (element.has.alias_password) {
							
							certificate.aliasPassword = substitute (element.att.alias_password);
							
						}
					
					case "dependency":
						
						//dependencyNames.push (substitute (element.att.name));
						dependencies.push (substitute (element.att.name));
					
					case "ios":
						
						if (target == Platform.IOS) {
							
							if (element.has.deployment) {
								
								var deployment = Std.parseFloat (substitute (element.att.deployment));
								
								if (deployment > config.ios.deployment) {
									
									config.ios.deployment = deployment;
									
								}
								
							}
							
							if (element.has.binaries) {
								
								var binaries = substitute (element.att.binaries);
								
								switch (binaries) {
									
									case "fat":
										
										ArrayHelper.addUnique (architectures, Architecture.ARMV6);
										ArrayHelper.addUnique (architectures, Architecture.ARMV7);
									
									case "armv6":
										
										ArrayHelper.addUnique (architectures, Architecture.ARMV6);
										architectures.remove (Architecture.ARMV7);
									
									case "armv7":
										
										ArrayHelper.addUnique (architectures, Architecture.ARMV7);
										architectures.remove (Architecture.ARMV6);
									
								}
								
							}
							
							if (element.has.devices) {
								
								config.ios.device = Reflect.field (IOSConfigDevice, substitute (element.att.devices).toUpperCase ());
								
							}
							
							if (element.has.compiler) {
								
								config.ios.compiler = substitute (element.att.compiler);
								
							}
							
						}
					
				}
				
			}
			
		}
		
	}
	
	
	private function parseWindowElement (element:Fast):Void {
		
		for (attribute in element.x.attributes ()) {
			
			var name = formatAttributeName (attribute);
			var value = substitute (element.att.resolve (attribute));
			
			if (name == "background") {
				
				value = StringTools.replace (value, "#", "");
				
				if (value.indexOf ("0x") == -1) {
					
					value = "0x" + value;
					
				}
				
				window.background = Std.parseInt (value);
				
			} else if (name == "orientation") {
				
				window.orientation = Reflect.field (Orientation, Std.string (value).toUpperCase ());
				
			} else {
				
				if (Reflect.hasField (window, name)) {
					
					Reflect.setField (window, name, value);
					
				}
				
			}
			//defines.set ("WIN_" + attribute.toUpperCase (), substitute (element.att.resolve (attribute)));
			
		}
		
	}
	
	
	public function process (projectFile:String, useExtensionPath:Bool):Void {
		
		var xml = null;
		var extensionPath = "";
		
		try {
			
			xml = new Fast (Xml.parse (File.getContent (projectFile)).firstElement ());
			extensionPath = Path.directory (projectFile);
			
		} catch (e:Dynamic) {
			
			LogHelper.error ("\"" + projectFile + "\" contains invalid XML data", e);
			
		}
		
		parseXML (xml, "", extensionPath);
		
	}
	
	
	private function substitute (string:String):String {
		
		var newString = string;
		
		while (varMatch.match (newString)) {
			
			newString = localDefines.get (varMatch.matched (1));
			
			if (newString == null) {
				
				newString = "";
				
			}
			
			newString = varMatch.matchedLeft () + newString + varMatch.matchedRight ();
			
		}
		
		return newString;
		
	}
	
	
	
}