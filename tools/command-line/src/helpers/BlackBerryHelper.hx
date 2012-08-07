package helpers;


import sys.io.Process;


class BlackBerryHelper {
	
	
	private static var binDirectory:String;
	private static var defines:Hash <String>;
	private static var targetFlags:Hash <String>;
	
	
	public static function createPackage (workingDirectory:String, descriptorFile:String, targetPath:String):Void {
		
		var args = [ "-package", targetPath, descriptorFile ];
		
		if (defines.exists ("KEY_STORE")) {
			
			args.push ("-keystore");
			args.push (PathHelper.tryFullPath (defines.get ("KEY_STORE")));
			
			if (defines.exists ("KEY_STORE_PASSWORD")) {
				
				args.push ("-storepass");
				args.push (defines.get ("KEY_STORE_PASSWORD"));
				
			}
			
		} else {
			
			args.push ("-devMode");
			
			if (!targetFlags.exists ("simulator")) {
				
				args.push ("-debugToken");
				args.push (PathHelper.tryFullPath (defines.get ("BLACKBERRY_DEBUG_TOKEN")));
				
			}
			
		}
		
		ProcessHelper.runCommand (workingDirectory, binDirectory + "blackberry-nativepackager", args);
		
		if (defines.exists ("KEY_STORE")) {
			
			args = [ "-keystore", PathHelper.tryFullPath (defines.get ("KEY_STORE")) ];
			
			if (defines.exists ("KEY_STORE_PASSWORD")) {
				
				args.push ("-storepass");
				args.push (defines.get ("KEY_STORE_PASSWORD"));
				
			}
			
			args.push (targetPath);
			
			ProcessHelper.runCommand (workingDirectory, binDirectory + "blackberry-signer", args);
			
		}
		
	}
	
	
	public static function deploy (workingDirectory:String, targetPath:String, run:Bool = true):Void {
		
		var deviceIP = defines.get ("BLACKBERRY_DEVICE_IP");
		var devicePassword = defines.get ("BLACKBERRY_DEVICE_PASSWORD");
		
		if (targetFlags.exists ("simulator")) {
			
			deviceIP = defines.get ("BLACKBERRY_SIMULATOR_IP");
			devicePassword = "playbook";
			
		}
		
		var args = [ "-installApp" ];
		
		if (run) {
			
			args.push ("-launchApp");
			
		}
		
		args = args.concat ([ "-device", deviceIP, "-password", devicePassword, targetPath ]);
		
		ProcessHelper.runCommand (workingDirectory, binDirectory + "blackberry-deploy", args);
		
	}
	
	
	public static function initialize (defines:Hash <String>, targetFlags:Hash <String>):Void {
		
		if (InstallTool.isWindows) {
			
			binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/win32/x86/usr/bin/";
			
		} else if (InstallTool.isMac) {
			
			binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/macosx/x86/usr/bin/";
			
		} else {
			
			binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/linux/x86/usr/bin/";
			
		}
		
		BlackBerryHelper.defines = defines;
		BlackBerryHelper.targetFlags = targetFlags;
		
	}
	
	
	public static function getAuthorID (workingDirectory:String):String {
		
		if (defines.exists ("BLACKBERRY_DEBUG_TOKEN")) {
			
			PathHelper.mkdir (workingDirectory);
			
			var cacheCwd = Sys.getCwd ();
			Sys.setCwd (workingDirectory);
			
			var process = new Process(binDirectory + "blackberry-nativepackager", [ "-listmanifest", PathHelper.escape (PathHelper.tryFullPath (defines.get ("BLACKBERRY_DEBUG_TOKEN"))) ]);
			var ret = process.stdout.readAll().toString();
			var ret2 = process.stderr.readAll().toString();
			process.exitCode(); //you need this to wait till the process is closed!
			process.close();
			
			Sys.setCwd (cacheCwd);
			
			if (ret != null) {
				
				var search = "Package-Author-Id: ";
				var index = ret.indexOf (search);
				
				if (index > -1) {
					
					var start = index + search.length;
					return ret.substr (start, ret.indexOf ("\n", index) - start);
					
				}
				
			}
			
		}
		
		if (targetFlags.exists ("simulator")) {
			
			return "gYAAgF-DMYiFsOQ3U6QvuW1fQDY";
			
		} else {
			
			return "";
			
		}
		
	}
	
	
	public static function trace (workingDirectory:String, targetPath:String):Void {
		
		var deviceIP = defines.get ("BLACKBERRY_DEVICE_IP");
		var devicePassword = defines.get ("BLACKBERRY_DEVICE_PASSWORD");
		
		if (targetFlags.exists ("simulator")) {
			
			deviceIP = defines.get ("BLACKBERRY_SIMULATOR_IP");
			devicePassword = "playbook";
			
		}
		
		ProcessHelper.runCommand (workingDirectory, binDirectory + "blackberry-deploy", [ "-getFile", "logs/log", "-", "-device", deviceIP, "-password", devicePassword, targetPath ] );
		
	}
		

}
