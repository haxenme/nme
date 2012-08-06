package helpers;


class WebOSHelper {
	
	
	private static var sdkDirectory:String;
	
	
	public static function createPackage (workingDirectory:String, targetPath:String):Void {
		
		runPalmCommand (workingDirectory, "package" , [ targetPath ]);
		
	}
	
	
	public static function initialize (defines:Hash <String>):Void {
		
		sdkDirectory = "";
		
		if (defines.exists ("PalmSDK")) {
			
			sdkDirectory = defines.get ("PalmSDK");
			
		} else {
			
			if (InstallTool.isWindows) {
				
				sdkDirectory = "c:\\Program Files (x86)\\HP webOS\\SDK\\";
				
			} else {
				
				sdkDirectory = "/opt/PalmSDK/Current/";
				
			}
			
		}
		
	}
	
	
	public static function install (workingDirectory:String, targetFile:String):Void {
		
		runPalmCommand (workingDirectory, "install", [ targetFile ]);
		
	}
	
	
	public static function launch (packageName:String):Void {
		
		runPalmCommand ("", "launch", [ packageName ]);
		
	}
	
	
	private static function runPalmCommand (workingDirectory:String, command:String, args:Array<String>):Void {
		
		if (InstallTool.isWindows) {
			
			var jarFile = sdkDirectory + "\\share\\jars\\webos-tools.jar";
			var newArgs = [ "-Dpalm.command=palm-" + command , "-jar", command ].concat (args);
			ProcessHelper.runCommand (workingDirectory, "java" , newArgs);
			
		} else {
			
			ProcessHelper.runCommand (workingDirectory, sdkDirectory + "/bin/palm-" + command, args);
			
		}
		
	}
	
	
	public static function trace (packageName:String, follow:Bool = true):Void {
		
		var args:Array <String> = [];
		
		if (follow) {
			
			args.push ("-f");
			
		}
		
		args.push (packageName);
		
		runPalmCommand ("", "log", args);
		
	}
		

}
