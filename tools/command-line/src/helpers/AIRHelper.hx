package helpers;





class AIRHelper {
	
	
	private static var defines:Hash <String>;
	private static var target:String;
	private static var targetFlags:Hash <String>;
	
	
	public static function initialize (defines:Hash <String>, targetFlags:Hash <String>, target:String):Void {
		
		AIRHelper.defines = defines;
		AIRHelper.targetFlags = targetFlags;
		AIRHelper.target = target;
		
	}
	
	
	public static function run (workingDirectory:String, targetPath:String, applicationXML:String, files:Array <String>, debug:Bool):Void {
		
		var airTarget = "air";
		
		if (target == "ios") {
			
			if (targetFlags.exists ("simulator")) {
				
				if (debug) {
					
					airTarget = "ipa-debug-interpreter-simulator";
					
				} else {
					
					airTarget = "ipa-test-interpreter-simulator";
					
				}
				
			} else {
				
				if (debug) {
					
					airTarget = "ipa-debug-interpreter";
					
				} else {
					
					airTarget = "ipa-ad-hoc";
					
				}
				
			}
			
		} else if (target == "android") {
			
			if (debug) {
				
				airTarget = "apk-debug";
				
			} else {
				
				airTarget = "apk";
				
			}
			
		}
		
		var args = [ "-package", "-storetype", defines.get ("KEY_STORE_TYPE"), "-keystore", defines.get ("KEY_STORE") ];
		
		if (defines.exists ("KEY_STORE_ALIAS")) {
			
			args.push ("-alias");
			args.push (defines.get ("KEY_STORE_ALIAS"));
			
		}
		
		if (defines.exists ("KEY_STORE_PASSWORD")) {
			
			args.push ("-storepass");
			args.push (defines.get ("KEY_STORE_PASSWORD"));
			
		}
		
		if (defines.exists ("KEY_STORE_ALIAS_PASSWORD")) {
			
			args.push ("-keypass");
			args.push (defines.get ("KEY_STORE_ALIAS_PASSWORD"));
			
		}
		
		args = args.concat ([ "-target", airTarget, targetPath, applicationXML ]);
		args = args.concat (files);
		//args = args.concat ([ sourcePath /*, "icon_16.png", "icon_32.png", "icon_48.png", "icon_128.png"*/ ]);
		
		ProcessHelper.runCommand (workingDirectory, defines.get ("AIR_SDK") + "/bin/adt", args);
		
	}
		

}
