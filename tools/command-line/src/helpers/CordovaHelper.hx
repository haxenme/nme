package helpers;


import sys.io.File;


class CordovaHelper {
	
	
	public static var contentPath = "www/";
	
	private static var defines:Hash <String>;
	private static var NME:String;
	private static var target:String;
	private static var targetFlags:Hash <String>;
	
	
	public static function build (workingDirectory:String, debug:Bool):Void {
		
		switch (target) {
			
			case "ios":
				
				var cordovaLib = defines.get ("CORDOVA_PATH") + "/lib/ios/CordovaLib";
				
				IOSHelper.build (cordovaLib, debug, [ "-project", "CordovaLib.xcodeproj" ]);
				IOSHelper.build (workingDirectory, debug, [ "CORDOVALIB=" + cordovaLib ]);
				
				if (!targetFlags.exists ("simulator")) {
		            
		            //var entitlements = buildDirectory + "/ios/" + defines.get("APP_FILE") + "/" + defines.get("APP_FILE") + "-Entitlements.plist";
		            IOSHelper.sign (workingDirectory, null, debug);
		            
		        }
			
		    case "blackberry":
		    	
				AntHelper.run (workingDirectory, [ "playbook", "build" ]);
			
		}
		
	}
	
	
	public static function create (targetPath:String, context:Dynamic):Void {
		
		PathHelper.removeDirectory (targetPath);
		ProcessHelper.runCommand ("", defines.get ("CORDOVA_PATH") + "/lib/" + target + "/bin/create", [ targetPath, defines.get ("APP_PACKAGE"), defines.get ("APP_FILE") ]);
		
		switch (target) {
			
			case "blackberry":
				
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
			
		}
		
	}
	
	
	public static function launch (workingDirectory:String, debug:Bool):Void {
		
		switch (target) {
		
			case "ios":
				
				IOSHelper.launch (workingDirectory, debug);
			
			case "blackberry":
				
				var safePackageName = StringTools.replace (defines.get ("APP_TITLE"), " ", "");
				
				BlackBerryHelper.deploy (workingDirectory, "build/" + safePackageName + ".bar");
			
		}
		
	}
	

}
