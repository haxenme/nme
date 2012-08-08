package helpers;


import sys.io.Process;
import sys.FileSystem;


class IOSHelper {
	
	
	private static var defines:Hash <String>;
	private static var NME:String;
	private static var targetFlags:Hash <String>;
	
	
	public static function build (workingDirectory:String, debug:Bool, additionalArguments:Array <String> = null):Void {
		
		var platformName:String = "iphoneos";
        
        if (targetFlags.exists("simulator")) {
        	
            platformName = "iphonesimulator";
            
        }
        
        var configuration:String = "Release";
        
        if (debug) {
        	
            configuration = "Debug";
            
        }
			
        var iphoneVersion:String = defines.get ("IPHONE_VER");
        var commands = [ "-configuration", configuration, "PLATFORM_NAME=" + platformName, "SDKROOT=" + platformName + iphoneVersion ];
			
        if (targetFlags.exists("simulator")) {
        	
            commands.push ("-arch");
            commands.push ("i386");
            
        }
        
        if (additionalArguments != null) {
        	
        	commands = commands.concat (additionalArguments);
        	
        }
			
        ProcessHelper.runCommand (workingDirectory, "xcodebuild", commands);
		
	}
	
	private static function getIOSVersion ():Void {
		
		if (!defines.exists("IPHONE_VER")) {
			if (!defines.exists("DEVELOPER_DIR")) {
		        var proc = new Process("xcode-select", ["--print-path"]);
		        var developer_dir = proc.stdout.readLine();
		        proc.close();
		        defines.set("DEVELOPER_DIR", developer_dir);
		    }
			var dev_path = defines.get("DEVELOPER_DIR") + "/Platforms/iPhoneOS.platform/Developer/SDKs";
         	
			if (FileSystem.exists (dev_path)) {
				var best = "";
            	var files = FileSystem.readDirectory (dev_path);
            	var extract_version = ~/^iPhoneOS(.*).sdk$/;
				
            	for (file in files) {
					if (extract_version.match (file)) {
						var ver = extract_version.matched (1);
						
                  		if (ver > best)
                     		best = ver;
               		}
            	}
				
            	if (best != "")
               		defines.set ("IPHONE_VER", best);
			}
      	}
		
	}
	
	
	public static function initialize (defines:Hash <String>, targetFlags:Hash <String>, NME:String):Void {
		
		IOSHelper.defines = defines;
		IOSHelper.NME = NME;
		IOSHelper.targetFlags = targetFlags;
		
		getIOSVersion ();
		
	}
	
	
	public static function launch (workingDirectory:String, debug:Bool):Void {
		
		var configuration = "Release";
			
        if (debug) {
        	
            configuration = "Debug";
            
        }
        
		if (targetFlags.exists ("simulator")) {
			
			var applicationPath = workingDirectory + "/build/" + configuration + "-iphonesimulator/" + defines.get ("APP_FILE") + ".app";
			var family:String = "iphone";
			
			if (targetFlags.exists ("ipad")) {
				
				family = "ipad";
				
			}
			
			var launcher:String = NME + "/tools/command-line/bin/ios-sim";
			Sys.command ("chmod", [ "+x", launcher ]);
			
			ProcessHelper.runCommand ("", launcher, [ "launch", FileSystem.fullPath (applicationPath), "--sdk", defines.get ("IPHONE_VER"), "--family", family ] );
			
		} else {
			
			var applicationPath = workingDirectory + "/build/" + configuration + "-iphoneos/" + defines.get ("APP_FILE") + ".app";
            var launcher = NME + "/tools/command-line/bin/fruitstrap";
	        Sys.command ("chmod", [ "+x", launcher ]);
	        
	        if (debug) {
	            
	            ProcessHelper.runCommand ("", launcher, [ "install", "--debug", "--timeout", "5", "--bundle", FileSystem.fullPath (applicationPath) ]);
	            
	        } else {
	            
	            ProcessHelper.runCommand ("", launcher, [ "install", "--debug", "--timeout", "5", "--bundle", FileSystem.fullPath (applicationPath) ]);
	            
	        }
            
		}
		
	}
	
	
	public static function sign (workingDirectory:String, entitlementsPath:String, debug:Bool):Void {
		
        var configuration:String = "Release";
		
        if (debug) {
        	
            configuration = "Debug";
            
        }
        
        var commands = [ "-s", "iPhone Developer" ];
        
        if (entitlementsPath != null) {
        	
        	commands.push ("--entitlements");
        	commands.push (entitlementsPath);
        	
        }
        
        var applicationPath:String = workingDirectory + "/build/" + configuration + "-iphoneos/" + defines.get ("APP_FILE") + ".app";
        commands.push (FileSystem.fullPath (applicationPath));
        
        ProcessHelper.runCommand ("", "codesign", commands, true, true);
		
	}
	

}
