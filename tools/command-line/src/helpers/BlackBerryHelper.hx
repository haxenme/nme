package helpers;


import haxe.io.Eof;
import sys.io.Process;


class BlackBerryHelper {
	
	
	private static var binDirectory:String;
	private static var defines:Hash <String>;
	private static var targetFlags:Hash <String>;
	
	
	public static function createPackage (workingDirectory:String, descriptorFile:String, targetPath:String):Void {
		
		var args = [ "-package", targetPath, descriptorFile ];
		
		if (defines.exists ("KEY_STORE") && !defines.exists ("KEY_STORE_PASSWORD")) {
			
			defines.set ("KEY_STORE_PASSWORD", prompt ("Keystore password", true));
			Sys.println ("");
			
		}
		
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
		
		var exe = binDirectory + "blackberry-nativepackager";
			
		if (InstallTool.isWindows) {
			
			exe += ".bat";
			
		}
		
		ProcessHelper.runCommand (workingDirectory, exe, args);
		
		if (defines.exists ("KEY_STORE")) {
			
			args = [ "-keystore", PathHelper.tryFullPath (defines.get ("KEY_STORE")) ];
			
			if (defines.exists ("KEY_STORE_PASSWORD")) {
				
				args.push ("-storepass");
				args.push (defines.get ("KEY_STORE_PASSWORD"));
				
			}
			
			args.push (targetPath);
			
			var exe = binDirectory + "blackberry-signer";
			
			if (InstallTool.isWindows) {
				
				exe += ".bat";
				
			}
			
			ProcessHelper.runCommand (workingDirectory, exe, args);
			
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
		
		var exe = binDirectory + "blackberry-deploy";
		
		if (InstallTool.isWindows) {
			
			exe += ".bat";
			
		}
		
		ProcessHelper.runCommand (workingDirectory, exe, args);
		
	}
	
	
	public static function getAuthorID (workingDirectory:String):String {
		
		if (defines.exists ("BLACKBERRY_DEBUG_TOKEN")) {
			
			PathHelper.mkdir (workingDirectory);
			
			var cacheCwd = Sys.getCwd ();
			Sys.setCwd (workingDirectory);
			
			var exe = binDirectory + "blackberry-nativepackager";
			
			if (InstallTool.isWindows) {
				
				exe += ".bat";
				
			}
			
			var process = new Process (exe, [ "-listmanifest", PathHelper.escape (PathHelper.tryFullPath (defines.get ("BLACKBERRY_DEBUG_TOKEN"))) ]);
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
					return StringTools.trim (ret.substr (start, ret.indexOf ("\n", index) - start));
					
				}
				
			}
			
		}
		
		if (targetFlags.exists ("simulator")) {
			
			return "gYAAgF-DMYiFsOQ3U6QvuW1fQDY";
			
		} else {
			
			return "";
			
		}
		
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
	
	
	private static function prompt (name:String, ?passwd:Bool):String {
		
		Sys.print (name + ": ");
		
		if (passwd) {
			var s = new StringBuf ();
			var c;
			while ((c = Sys.getChar(false)) != 13)
				s.addChar (c);
			return s.toString ();
		}
		
		try {
			
			return Sys.stdin ().readLine ();
			
		} catch (e:Eof) {
			
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
		
		var exe = binDirectory + "blackberry-deploy";
		
		if (InstallTool.isWindows) {
			
			exe += ".bat";
			
		}
		
		ProcessHelper.runCommand (workingDirectory, exe, [ "-getFile", "logs/log", "-", "-device", deviceIP, "-password", devicePassword, targetPath ] );
		
	}
		

}
