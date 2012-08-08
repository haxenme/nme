package helpers;


class CordovaHelper {
	
	
	public static var contentPath = "www/";
	
	private static var defines:Hash <String>;
	private static var NME:String;
	private static var target:String;
	private static var targetFlags:Hash <String>;
	
	
	public static function build (workingDirectory:String, debug:Bool):Void {
		
		if (target == "ios") {
			
			var cordovaLib = defines.get ("CORDOVA_PATH") + "/lib/ios/CordovaLib";
			
			IOSHelper.build (cordovaLib, debug, [ "-project", "CordovaLib.xcodeproj" ]);
			IOSHelper.build (workingDirectory, debug, [ "CORDOVALIB=" + cordovaLib ]);
			
			if (!targetFlags.exists ("simulator")) {
	            
	            //var entitlements = buildDirectory + "/ios/" + defines.get("APP_FILE") + "/" + defines.get("APP_FILE") + "-Entitlements.plist";
	            
	            IOSHelper.sign (workingDirectory, null, debug);
	            
	        }
			
		}
		
	}
	
	
	public static function create (targetPath:String):Void {
		
		PathHelper.removeDirectory (targetPath);
		ProcessHelper.runCommand ("", defines.get ("CORDOVA_PATH") + "/lib/" + target + "/bin/create", [ targetPath, defines.get ("APP_PACKAGE"), defines.get ("APP_FILE") ]);
		
		if (target == "ios") {
			
			
			
		}
		
	}
	
	
	public static function initialize (defines:Hash <String>, targetFlags:Hash <String>, target:String, NME:String):Void {
		
		CordovaHelper.defines = defines;
		CordovaHelper.NME = NME;
		CordovaHelper.target = target;
		CordovaHelper.targetFlags = targetFlags;
		
		if (target == "ios") {
			
			IOSHelper.initialize (defines, targetFlags, NME);
			
		}
		
	}
	
	
	public static function launch (workingDirectory:String, debug:Bool):Void {
		
		if (target == "ios") {
			
			IOSHelper.launch (workingDirectory, debug);
			
		}
		
	}
	

}
