package;


import haxe.io.Path;


class NMEProject {
	
	
	public var meta:MetaData;
	public var app:App;
	public var window:Window;
	
	public var platformType:PlatformType;
	
	public var architectures:Array <Architecture>;
	public var assets:Array <Asset>;
	public var certificate:Keystore;
	public var dependencies:Array <String>;
	public var haxedefs:Array <String>;
	public var haxeflags:Array <String>;
	public var haxelibs:Array <String>;
	public var icons:Array <Icon>;
	public var javaPaths:Array <String>;
	public var libraries:Array <String>;
	public var ndlls:Array <NDLL>;
	public var paths:Array <String>;
	public var sources:Array <String>;
	
	public var command (getCommand, setCommand):String;
	public var host (getHost, null):Platform;
	public var target (getTarget, setTarget):Platform;
	
	private var _command:String;
	private var _target:Platform;
	
	private static var buildCommand:String;
	private static var buildHost:Platform;
	private static var buildTarget:Platform;
	
	
	
	// add pre-build, post-build hooks
	
	
	public static function create (className:String, command:String, targetName:String, debug:Bool, defines:Hash <String>, userDefines:Hash <String>, includePaths:Array <String>, targetFlags:Hash <String>) {
		
		buildCommand = command;
		
		if (new EReg ("window", "i").match (Sys.systemName ())) {
			
			buildHost = Platform.WINDOWS;
			
		} else if (new EReg ("linux", "i").match (Sys.systemName ())) {
			
			buildHost = Platform.LINUX;
			
		} else if (new EReg ("mac", "i").match (Sys.systemName ())) {
			
			buildHost = Platform.MAC;
			
		}
		
		switch (targetName) {
			
			case "cpp":
				
				buildTarget = buildHost;
				
			case "neko":
				
				buildTarget = buildHost;
			
			default:
				
				buildTarget = Reflect.field (Platform, targetName.toUpperCase ());
		
		}
		
		return Type.createInstance (Type.resolveClass (className), []);
		
	}
	
	
	public function new () {
		
		switch (target) {
			
			case Platform.FLASH, Platform.HTML5:
				
				platformType = PlatformType.WEB;
				
			case Platform.ANDROID, Platform.BLACKBERRY, Platform.IOS, Platform.WEBOS:
				
				platformType = PlatformType.MOBILE;
				
			case Platform.WINDOWS, Platform.MAC, Platform.LINUX:
				
				platformType = PlatformType.DESKTOP;
			
		}
		
		meta = { title: "MyApplication", description: "", packageName: "com.example.myapp", version: "1.0.0", company: "Example, Inc.", buildNumber: "1", companyID: "" }
		app = { main: "Main", file: "MyApplication", path: "bin", preloader: "NMEPreloader", swfVersion: "11", minimumSWFVersion: "11", url: "" }
		window = { width: 800, height: 600, background: 0xFFFFFF, fps: 30, resizable: true, borderless: false, orientation: "auto", vsync: false, fullscreen: false, antialiasing: 0, shaders: false }
		
		assets = new Array <Asset> ();
		dependencies = new Array <String> ();
		haxedefs = new Array <String> ();
		haxeflags = new Array <String> ();
		haxelibs = new Array <String> ();
		icons = new Array <Icon> ();
		javaPaths = new Array <String> ();
		libraries = new Array <String> ();
		ndlls = new Array <NDLL> ();
		paths = new Array <String> ();
		sources = new Array <String> ();
		
	}
	
	
	public function include (path:String):Void {
		
		// extend project file somehow?
		
	}
	
	
	public function includeAssets (path:String, rename:String = null, include:Array <String> = null, exclude:Array <String> = null):Void {
		
		if (include == null) {
			
			include = [ "*" ];
			
		}
		
		if (exclude == null) {
			
			exclude = [];
			
		}
		
		// populate assets array with files in the directory
		
	}
	
	
	public function path (value:String):Void {
		
		if (host == Platform.WINDOWS) {
			
			setenv ("PATH", value + ";" + Sys.getEnv ("PATH"));
			
		} else {
			
			setenv ("PATH", value + ":" + Sys.getEnv ("PATH"));
			
		}
		
	}
	
	
	public function setenv (name:String, value:String):Void {
		
		Sys.putEnv (name, value);
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function getCommand ():String {
			
		if (_command == null) {
			
			_command = NMEProject.buildCommand;
			
		}
		
		return _command;
		
	}
	
	
	private function setCommand (value:String):String {
			
		return _command = value;
		
	}
	
	
	private function getHost ():Platform {
		
		return NMEProject.buildHost;
		
	}
	
	
	private function getTarget ():Platform {
			
		if (_target == null) {
			
			_target = NMEProject.buildTarget;
			
		}
		
		return _target;
		
	}
	
	
	private function setTarget (value:Platform):Platform {
			
		return _target = value;
		
	}
	

}


typedef App = {
	
	var file:String;
	var main:String;
	var path:String;
	var minimumSWFVersion:String;
	var preloader:String;
	var swfVersion:String;
	var url:String;
	
}

enum Architecture {
	
	ARMV6;
	ARMV7;
	X86;
	X64;
	
}

class Asset {
	
	public var data:Dynamic;
	public var embed:Bool;
	public var glyphs:String;
	public var id:String;
	public var path:String;
	public var rename:String;
	public var type:AssetType;
	
	public function new (path:String, rename:String = "", type:AssetType = null, embed:Bool = true) {
		
		this.path = path;
		
		if (rename == "") {
			
			this.rename = path;
			
		} else {
			
			this.rename = rename;
			
		}
		
		if (type == null) {
			
			var extension = Path.extension (path);
			
			switch (extension.toLowerCase ()) {
				
				case "jpg", "jpeg", "png", "gif":
					
					this.type = AssetType.IMAGE;
				
				case "otf", "ttf":
					
					this.type = AssetType.FONT;
				
				case "wav", "ogg":
					
					this.type = AssetType.SOUND;
				
				case "mp3", "mp2":
					
					this.type = AssetType.MUSIC;
				
				case "text", "txt", "json", "xml", "svg":
					
					this.type = AssetType.TEXT;
				
				default:
					
					this.type = AssetType.BINARY;
				
			}
			
		}
		
	}
	
}

enum AssetType {
	
	BINARY;
	FONT;
	IMAGE;
	MUSIC;
	SOUND;
	TEMPLATE;
	TEXT;
	
}

class Icon {
	
	public var height:Int;
	public var path:String;
	public var size:Int;
	public var width:Int;
	
	public function new (path:String, size:Int = -1) {
		
		this.path = path;
		this.size = height = width = size;
		
	}
	
}

class Keystore {
	
	public var alias:String;
	public var aliasPassword:String;
	public var password:String;
	public var path:String;
	public var type:String;
	
	public function new (path:String, password:String = null, alias:String = "", aliasPassword:String = null) {
		
		this.path = path;
		this.password = password;
		this.alias = alias;
		this.aliasPassword = aliasPassword;
		
	}
	
}

typedef MetaData = {
	
	var buildNumber:String;
	var company:String;
	var companyID:String;
	var description:String;
	var packageName:String;
	var title:String;
	var version:String;
	
}

class NDLL {
	
	public var haxelib:String;
	public var name:String;
	
	public function new (name:String, haxelib:String = "") {
		
		this.name = name;
		this.haxelib = haxelib;
		
	}
	
}

enum Platform {
	
	ANDROID;
	BLACKBERRY;
	FLASH;
	HTML5;
	IOS;
	LINUX;
	MAC;
	WINDOWS;
	WEBOS;

}

enum PlatformType {
	
	DESKTOP;
	MOBILE;
	WEB;

}

typedef Window = { 
	
	var width:Int;
	var height:Int;
	var background:Int;
	var fps:Int;
	var resizable:Bool;
	var borderless:Bool;
	var vsync:Bool;
	var fullscreen:Bool;
	var antialiasing:Int;
	var orientation:String;
	var shaders:Bool;
	
}