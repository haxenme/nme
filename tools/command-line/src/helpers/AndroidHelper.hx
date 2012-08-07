package helpers;


import sys.FileSystem;


class AndroidHelper {
	
	
	private static var adbName:String;
	private static var adbPath:String;
	private static var defines:Hash <String>;
	
	
	public static function build (projectDirectory:String):Void {
		
		if (defines.exists ("JAVA_HOME")) {
			
			Sys.putEnv ("JAVA_HOME", defines.get ("JAVA_HOME"));
			
		}
		
		if (defines.exists ("ANDROID_SDK")) {
			
			Sys.putEnv ("ANDROID_SDK", defines.get ("ANDROID_SDK"));
			
		}
		
		var ant:String = defines.get ("ANT_HOME");
		
		if (ant == null || ant == "") {
			
			ant = "ant";
			
		} else {
			
			ant += "/bin/ant";
			
		}
		
		var build:String = "debug";
		
		if (defines.exists ("KEY_STORE")) {
			
			build = "release";
			
		}
		
		// Fix bug in Android build system, force compile
		
		var buildProperties = projectDirectory + "/bin/build.prop";
		
		if (FileSystem.exists (buildProperties)) {
			
			FileSystem.deleteFile (buildProperties);
			
		}
		
		ProcessHelper.runCommand (projectDirectory, ant, [ build ]);
		
	}
	
	
	private static function getADB ():Void {
		
		adbPath = defines.get ("ANDROID_SDK") + "/tools/";
		adbName = "adb";
		
		if (defines.get ("HOST") == "windows") {
			
			adbName += ".exe";
			
		}
		
		if (!FileSystem.exists (adbPath + adbName)) {
			
			adbPath = defines.get ("ANDROID_SDK") + "/platform-tools/";
			
		}
		
		if (!InstallTool.isWindows) {
			
			adbName = "./" + adbName;
			
		}
		
	}
	
	
	public static function initialize (defines:Hash <String>):Void {
		
		AndroidHelper.defines = defines;
		
		getADB ();
		
	}
	
	
	public static function install (targetPath:String):Void {
		
		ProcessHelper.runCommand (adbPath, adbName, [ "install", "-r", targetPath ]);
		
	}
	
	
	public static function run (activityName:String):Void {
		
		ProcessHelper.runCommand (adbPath, adbName, [ "shell", "am", "start", "-a", "android.intent.action.MAIN", "-n", activityName ]);
		
	}
	
	
	public static function trace (debug:Bool):Void {
		
		// Use -DFULL_LOGCAT or  <set name="FULL_LOGCAT" /> if you do not want to filter log messages
		
		if (defines.exists("FULL_LOGCAT")) {
			
			ProcessHelper.runCommand (adbPath, adbName, [ "logcat", "-c" ]);
			ProcessHelper.runCommand (adbPath, adbName, [ "logcat" ]);
			
		} else if (debug) {
			
			var filter = "*:E";
			var includeTags = [ "NME", "Main", "GameActivity", "GLThread", "trace" ];
			
			for (tag in includeTags) {
				
				filter += " " + tag + ":D";
				
			}
			
			Sys.println (filter);
			
			ProcessHelper.runCommand (adbPath, adbName, [ "logcat", filter ]);
			
		} else {
			
			ProcessHelper.runCommand (adbPath, adbName, [ "logcat", "*:S trace:I" ]);
			
		}
		
	}
	
	
	public static function uninstall (packageName:String):Void {
		
		ProcessHelper.runCommand (adbPath, adbName, [ "uninstall", packageName ]);
		
	}
	

}
