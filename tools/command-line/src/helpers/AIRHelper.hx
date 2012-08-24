package helpers;





class AIRHelper {
	
	
	private static var defines:Hash <String>;
	private static var target:String;
	private static var targetFlags:Hash <String>;
	
	
	public static function initialize (defines:Hash <String>, targetFlags:Hash <String>, target:String, NME:String):Void {
		
		AIRHelper.defines = defines;
		AIRHelper.targetFlags = targetFlags;
		AIRHelper.target = target;
		
		switch (target) {
			
			case "ios":
				
				IOSHelper.initialize (defines, targetFlags, NME);
			
		}
		
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
		
		var signingOptions = [ "-storetype", defines.get ("KEY_STORE_TYPE"), "-keystore", defines.get ("KEY_STORE") ];
		
		if (defines.exists ("KEY_STORE_ALIAS")) {
			
			signingOptions.push ("-alias");
			signingOptions.push (defines.get ("KEY_STORE_ALIAS"));
			
		}
		
		if (defines.exists ("KEY_STORE_PASSWORD")) {
			
			signingOptions.push ("-storepass");
			signingOptions.push (defines.get ("KEY_STORE_PASSWORD"));
			
		}
		
		if (defines.exists ("KEY_STORE_ALIAS_PASSWORD")) {
			
			signingOptions.push ("-keypass");
			signingOptions.push (defines.get ("KEY_STORE_ALIAS_PASSWORD"));
			
		}
		
		var args = [ "-package" ];
		
		if (airTarget == "air") {
			
			args = args.concat (signingOptions);
			args.push ("-target");
			args.push ("air");
			
		} else {
			
			args.push ("-target");
			args.push (airTarget);
			args = args.concat (signingOptions);
			
		}
		
		if (target == "ios") {
			
			//args.push ("-provisioning-profile");
			//args.push ("");
			
		}
		
		args = args.concat ([ targetPath, applicationXML ]);
		
		
		if (target == "ios") {
			
			args.push ("-platformsdk");
			args.push (IOSHelper.getSDKDirectory ());
			
		}
		
		args = args.concat (files);
		//args = args.concat ([ sourcePath /*, "icon_16.png", "icon_32.png", "icon_48.png", "icon_128.png"*/ ]);
		
		ProcessHelper.runCommand (workingDirectory, defines.get ("AIR_SDK") + "/bin/adt", args);
		
	}
		

}
