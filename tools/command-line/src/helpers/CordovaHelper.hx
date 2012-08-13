package helpers;


import sys.io.File;
import sys.FileSystem;


class CordovaHelper {
	
	
	public static var contentPath = "www/";
	
	private static var defines:Hash <String>;
	private static var NME:String;
	private static var target:String;
	private static var targetFlags:Hash <String>;
	
	
	public static function build (workingDirectory:String, debug:Bool):Void {
		
		switch (target) {
			
			case "ios":
				
				// temporary hack
				ProcessHelper.runCommand ("", "defaults", [ "write", "com.apple.dt.Xcode", "IDEApplicationwideBuildSettings", "-dict-add", "CORDOVALIB", defines.get ("CORDOVA_PATH") ]);
				
				
				var cordovaLib = defines.get ("CORDOVA_PATH") + "/lib/ios/CordovaLib";
				
				IOSHelper.build (workingDirectory, debug, [ "CORDOVALIB=" + cordovaLib ]);
				
				if (!targetFlags.exists ("simulator")) {
		            
		            //var entitlements = buildDirectory + "/ios/" + defines.get("APP_FILE") + "/" + defines.get("APP_FILE") + "-Entitlements.plist";
		            IOSHelper.sign (workingDirectory, null, debug);
		            
		        }
			
		    case "blackberry":
		    	
		    	if (targetFlags.exists ("bbos")) {
		    		
		    		AntHelper.run (workingDirectory, [ "blackberry", "build", "-Dcode.sign=false" ]);
		    		
		    	} else {
		    		
					AntHelper.run (workingDirectory, [ "playbook", "build" ]);
					
				}
			
			case "android":
				
				AndroidHelper.build (workingDirectory);
			
		}
		
	}
	
	
	public static function create (workingDirectory:String, targetPath:String, context:Dynamic):Void {
		
		//if (!FileSystem.exists (targetPath)) {
		
			if (target == "android") {
				
				Sys.putEnv ("ANDROID_BIN", defines.get ("ANDROID_SDK") + "/tools/android");
				
			}
			
			PathHelper.removeDirectory (targetPath);
			ProcessHelper.runCommand (workingDirectory, defines.get ("CORDOVA_PATH") + "/lib/" + target + "/bin/create", [ targetPath, defines.get ("APP_PACKAGE"), defines.get ("APP_FILE") ]);
			
		//}
		
		switch (target) {
			
			case "ios":
				
				FileHelper.copyFile (NME + "/templates/cordova/ios/template/PROJ/PROJ-Info.plist", targetPath + "/" + defines.get ("APP_FILE") + "/" + defines.get ("APP_FILE") + "-Info.plist", context);
			
			case "blackberry":
				
				context.BLACKBERRY_AUTHOR_ID = BlackBerryHelper.getAuthorID (targetPath);
				FileHelper.recursiveCopy (NME + "/templates/cordova/blackberry/template", targetPath, context);
			
		}
		
	}
	
	
	public static function initialize (defines:Hash <String>, targetFlags:Hash <String>, target:String, NME:String):Void {
		
		CordovaHelper.defines = defines;
		CordovaHelper.NME = NME;
		CordovaHelper.target = target;
		CordovaHelper.targetFlags = targetFlags;
		
		switch (target) {
			
			case "ios":
				
				IOSHelper.initialize (defines, targetFlags, NME);
			
			case "blackberry":
				
				AntHelper.initialize (defines);
				BlackBerryHelper.initialize (defines, targetFlags);
			
			case "android":
				
				AndroidHelper.initialize (defines);
			
		}
		
	}
	
	
	public static function launch (workingDirectory:String, debug:Bool):Void {
		
		switch (target) {
		
			case "ios":
				
				IOSHelper.launch (workingDirectory, debug);
			
			case "blackberry":
				
				if (targetFlags.exists ("bbos")) {
		    		
		    		if (targetFlags.exists ("simulator")) {
		    			
		    			AntHelper.run (workingDirectory, [ "blackberry", "load-simulator" ]);
		    			
		    		} else {
		    			
		    			AntHelper.run (workingDirectory, [ "blackberry", "load-device" ]);
		    			
		    		}
		    		
		    	} else {
					
					var safePackageName = StringTools.replace (defines.get ("APP_TITLE"), " ", "");
					BlackBerryHelper.deploy (workingDirectory, "build/" + safePackageName + ".bar");
				
				}
			
			case "android":
				
				var build:String = "debug";
				
				if (defines.exists ("KEY_STORE")) {
					
					build = "release";
					
				}
				
				AndroidHelper.install (FileSystem.fullPath (workingDirectory) + "/bin/" + defines.get ("APP_FILE") + "-" + build + ".apk");
				AndroidHelper.run (defines.get ("APP_PACKAGE") + "/" + defines.get ("APP_PACKAGE") + "." + defines.get ("APP_FILE"));
			
		}
		
	}
	

}
