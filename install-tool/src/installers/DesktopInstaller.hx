package installers;


import neko.io.Path;
import neko.io.Process;
import neko.Lib;
import neko.Sys;
import data.Asset;


class DesktopInstaller extends InstallerBase {
	
	
	private var targetDir:String;
	private var targetName:String;
	
	
	override function build ():Void {
		
		mkdir (getBuildDir ());
		mkdir (getExeDir ());
		
		recursiveCopy (NME + "/install-tool/haxe", targetDir + "/haxe");
		recursiveCopy (NME + "/install-tool/" + getVM () + "/hxml", targetDir + "/haxe");
		
		var hxml:String = targetDir + "/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
		var exe = getExeDir () + "/" + getExeName();
		
		copyResultTo(exe);
		
		if (!InstallTool.isWindows) {
			
			runCommand ("", "chmod", [ "755", exe ]);
			
		} else {
			
			// Setting the icon overwrites this appended neko data - must reverse this...
			
			if (getVM () != "neko") {
				
				icons.setWindowsIcon (defines.get ("APP_ICO"), targetDir + "/haxe", exe);
				
			}
			
		}
		
	}
	
	
	private function copyResultTo (inExe:String):Void {
		
		throw "copyResultTo : Not implemented";
		
	}
	
	
	override function generateContext ():Void {
		
		/*if (defines.exists ("NME_64")) {
			
			targetName += "64";
			
		}*/
		
		compilerFlags.push ("-cp " + targetDir + "/haxe");
		
		super.generateContext ();
		
		updateIcon ();
		
	}
	
	
	private function get64 ():String {
		
		if (defines.exists ("NME_64")) {
			
			return "64";
			
		}
		
		return "";
		
	}
	
	
	private function getBuildDir ():String {
		
		return targetDir + "/obj";
		
	}
	
	
	private function getCwd ():String {
		
		if (InstallTool.isWindows) {
			
			return ".\\";
			
		}
		
		return "./";
		
	}

	
	private function getContentDir ():String {
		
		if (targetName == "mac") {
			
			return targetDir + "/bin/" + defines.get ("APP_FILE") + ".app/Contents/Resources/";
			
		}
		
		return targetDir + "/bin/";
		
	}
	

	private function getExeDir ():String {
		
		if (targetName == "mac") {
			
			return targetDir + "/bin/" + defines.get ("APP_FILE") + ".app/Contents/MacOS/";
			
		}
		
		return targetDir + "/bin/";
		
	}
	

	private function getExeName ():String {
		
		if (targetName == "windows") {
			
			return defines.get ("APP_FILE") + ".exe";
			
		}
		
		return defines.get ("APP_FILE");
		
	}
	
	
	private function getVM ():String { 
		
		throw "getVM not implemented.";
		return ""; 
		
	}
	
	
	override function onCreate () {
		
		if (target == "neko") {
			
			if (targetFlags.exists ("windows")) {
				
				targetName = "windows";
				
			} else if (targetFlags.exists ("mac")) {
				
				targetName = "mac";
				
				for (asset in assets) {
					
					asset.targetPath = asset.resourceName = asset.flatName;
					
				}
				
			} else if (targetFlags.exists ("linux")) {
				
				targetName = "linux";
				
			}
			
		} else {
			
			if (InstallTool.isMac) {
				
				targetName = "mac";
				
				for (asset in assets) {
					
					asset.targetPath = asset.resourceName = asset.flatName;
					
				}
				
			} else if (InstallTool.isWindows) {
				
				targetName = "windows";
				
			} else if (InstallTool.isLinux) {
				
				targetName = "linux";
				
			} else {
				
				throw "Unknown desktop target.";
				
			}
			
		}
		
		targetDir = buildDirectory + "/" + getVM () + "/" + targetName + get64 ();
		
	}



	override function run ():Void {
		
		if (defines.exists (targetName)) {
			
			runCommand (getExeDir (), getCwd () + getExeName (), []);
			
		} else {
			
			print ("Skipping: Cannot run an application that is cross-compiled for another platform");
			
		}
		
	}
	
	
	override function update ():Void {
		
		var exe_dir = getExeDir ();
		mkdir (exe_dir);
		
		recursiveCopy (NME + "/install-tool/haxe", targetDir + "/haxe");
		recursiveCopy (NME + "/install-tool/cpp/hxml", targetDir + "/haxe");
		
		var system_name = targetName.substr (0, 1).toUpperCase () + targetName.substr (1) + get64 ();
		
		for (ndll in ndlls) {
			
			var extension:String = ".ndll";
			
			// This messes with the exe when neko is appended to the exe
			if (ndll.haxelib == "") {

				if (targetName == "windows") {
					
					extension = ".dll";
					
				} else if (targetName == "linux") {
					
					extension = ".dso";
					
				} else if (targetName == "mac") {
					
					extension = ".dylib";
					
				}
				
			}
			
			copyIfNewer (ndll.getSourcePath (system_name, ndll.name + extension), exe_dir + ndll.name + extension);
			
		}
		
		var content_dir = getContentDir ();
		
		for (asset in assets) {
			
			mkdir (Path.directory (content_dir + asset.targetPath));
			copyIfNewer (asset.sourcePath, content_dir + asset.targetPath );
			
		}

		if (InstallTool.isMac) {
			
			mkdir (content_dir);
			
			var filename =  icons.createMacIcon (content_dir);
			
			if (addFile(filename)) {
				
				context.HAS_ICON = true;
				
			}
			
			copyFile(NME + "/install-tool/mac/Info.plist", targetDir + "/bin/" + defines.get ("APP_FILE") + ".app/Contents/Info.plist", true);
			
		}
		
	}


	private function updateIcon () {
		
		if (!InstallTool.isMac && icons.hasIcons ()) {
			
			var icon_name = icons.findIcon (32, 32);
			
			if (icon_name == "") {
				
				mkdir(targetDir + "/haxe");
				
				var tmp_name = targetDir + "/haxe/icon.png";
				
				if (icons.updateIcon (32, 32, tmp_name)) {
					
					icon_name = tmp_name;
					
				}
				
			}
			
			if (icon_name != "") {
				
				assets.push (new Asset (icon_name, "icon.png", Asset.TYPE_IMAGE, "icon.png", "1"));
				context.WIN_ICON = "icon.png";
				
			}
			
		}
		
	}
	
	
}