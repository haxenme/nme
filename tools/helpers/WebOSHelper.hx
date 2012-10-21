


class WebOSHelper {
	
	
	public static function createPackage (project:NMEProject, workingDirectory:String, targetPath:String):Void {
		
		runPalmCommand (project, workingDirectory, "package" , [ targetPath ]);
		
	}
	
	
	private static function getPackageName (project:NMEProject):String {
		
		return project.meta.packageName + "_" + project.meta.version + "_all.ipk";
		
	}
	
	
	public static function install (project:NMEProject, workingDirectory:String):Void {
		
		runPalmCommand (project, workingDirectory, "install", [ getPackageName (project) ]);
		
	}
	
	
	public static function launch (project:NMEProject):Void {
		
		runPalmCommand (project, "", "launch", [ getPackageName (project) ]);
		
	}
	
	
	private static function runPalmCommand (project:NMEProject, workingDirectory:String, command:String, args:Array<String>):Void {
		
		var sdkDirectory = "";
		
		if (project.environment.exists ("PalmSDK")) {
			
			sdkDirectory = project.environment.get ("PalmSDK");
			
		} else {
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				sdkDirectory = "c:\\Program Files (x86)\\HP webOS\\SDK\\";
				
			} else {
				
				sdkDirectory = "/opt/PalmSDK/Current/";
				
			}
			
		}
		
		ProcessHelper.runCommand (workingDirectory, sdkDirectory + "/bin/palm-" + command, args);
		
	}
	
	
	public static function trace (project:NMEProject, follow:Bool = true):Void {
		
		var args = [];
		
		if (follow) {
			
			args.push ("-f");
			
		}
		
		args.push (project.meta.packageName);
		
		runPalmCommand (project, "", "log", args);
		
	}
		

}
