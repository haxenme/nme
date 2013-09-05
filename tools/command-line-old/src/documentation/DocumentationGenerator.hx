package documentation;


import helpers.PathHelper;
import helpers.ProcessHelper;
import installers.InstallerBase;
import sys.FileSystem;


/**
 * ...
 * @author Joshua Granick
 */

class DocumentationGenerator extends InstallerBase {
	
	
	public function new () {
		
		super ();
		
		document ();
		
	}
	
	
	private function document ():Void {
		
		var paths = getTypePaths ();
		
		if (paths.length > 0) {
			
			var docsDirectory = defines.get ("DOCS_DIR");
			PathHelper.mkdir (docsDirectory);
			
			var relativePathPrefix = "";
			
			var pathElements = docsDirectory.split ("/");
			
			for (pathElement in pathElements) {
				
				if (pathElement != "") {
					
					relativePathPrefix += "../";
					
				}
				
			}
			
			var commands = new Array <String> ();
			
			for (path in paths) {
				
				commands.push (relativePathPrefix + path);
				
			}
			
			if (defines.exists ("DOCS_FILTER")) {
				
				var filters:Array <String> = defines.get ("DOCS_FILTER").split (" ");
				
				for (filter in filters) {
					
					commands.push ("-f");
					commands.push (filter);
					
				}
				
			}
			
			ProcessHelper.runCommand (docsDirectory, "haxedoc", commands);
			
		}
		
	}
	
	
	private function getTypePaths ():Array <String> {
		
		var paths = new Array <String> ();
		
		var androidPath:Bool = false;
		var cppWindowsPath:Bool = false;
		var cppMacPath:Bool = false;
		var cppLinuxPath:Bool = false;
		var nekoWindowsPath:Bool = false;
		var nekoMacPath:Bool = false;
		var nekoLinuxPath:Bool = false;
		var flashPath:Bool = false;
		var iOSPath:Bool = false;
		var webOSPath:Bool = false;
		var html5Path:Bool = false;
		
		if (target == "") {
			
			androidPath = true;
			cppWindowsPath = true;
			cppMacPath = true;
			cppLinuxPath = true;
			nekoWindowsPath = true;
			nekoMacPath = true;
			nekoLinuxPath = true;
			flashPath = true;
			iOSPath = true;
			webOSPath = true;
			html5Path = true;
			
		}
		
		if (target == "android") {
			
			androidPath = true;
			
		}
		
		if (target == "cpp") {
			
			if (!targetFlags.exists ("windows") && !targetFlags.exists ("mac") && !targetFlags.exists ("linux")) {
				
				cppWindowsPath = true;
				cppMacPath = true;
				cppLinuxPath = true;
				
			} else if (targetFlags.exists ("windows")) {
				
				cppWindowsPath = true;
				
			} else if (targetFlags.exists ("mac")) {
				
				cppMacPath = true;
				
			} else if (targetFlags.exists ("linux")) {
				
				cppLinuxPath = true;
				
			}
			
		}
		
		if (target == "neko") {
			
			if (!targetFlags.exists ("windows") && !targetFlags.exists ("mac") && !targetFlags.exists ("linux")) {
				
				nekoWindowsPath = true;
				nekoMacPath = true;
				nekoLinuxPath = true;
				
			} else if (targetFlags.exists ("windows")) {
				
				nekoWindowsPath = true;
				
			} else if (targetFlags.exists ("mac")) {
				
				nekoMacPath = true;
				
			} else if (targetFlags.exists ("linux")) {
				
				nekoLinuxPath = true;
				
			}
			
		}
		
		if (target == "windows") {
			
			if (InstallTool.isWindows) {
				
				cppWindowsPath = true;
				
			} else {
				
				nekoWindowsPath = true;
				
			}
			
		}
		
		if (target == "mac") {
			
			if (InstallTool.isMac) {
				
				cppMacPath = true;
				
			} else {
				
				nekoMacPath = true;
				
			}
			
		}
		
		if (target == "linux") {
			
			if (InstallTool.isLinux) {
				
				cppLinuxPath = true;
				
			} else {
				
				nekoLinuxPath = true;
				
			}
			
		}
		
		if (target == "flash") {
			
			flashPath = true;
			
		}
		
		if (target == "webos") {
			
			webOSPath = true;
			
		}
		
		if (target == "ios") {
			
			iOSPath = true;
			
		}
		
		if (target == "html5") {
			
			html5Path = true;
			
		}
		
		if (androidPath) {
			
			paths.push (buildDirectory + "/android/types.xml");
			
		}
		
		if (cppWindowsPath) {
			
			paths.push (buildDirectory + "/cpp/windows/types.xml");
			
		}
		
		if (cppMacPath) {
			
			paths.push (buildDirectory + "/cpp/mac/types.xml");
			
		}
		
		if (cppLinuxPath) {
			
			paths.push (buildDirectory + "/cpp/linux/types.xml");
			
		}
		
		if (nekoWindowsPath) {
			
			paths.push (buildDirectory + "/neko/windows/types.xml");
			
		}
		
		if (nekoMacPath) {
			
			paths.push (buildDirectory + "/neko/mac/types.xml");
			
		}
		
		if (nekoLinuxPath) {
			
			paths.push (buildDirectory + "/neko/linux/types.xml");
			
		}
		
		if (webOSPath) {
			
			paths.push (buildDirectory + "/webos/types.xml");
			
		}
		
		if (iOSPath) {
			
			paths.push (buildDirectory + "/ios/types.xml");
			
		}
		
		if (flashPath) {
			
			paths.push (buildDirectory + "/flash/types.xml");
			
		}
		
		if (html5Path) {
			
			paths.push (buildDirectory + "/html5/types.xml");
			
		}
		
		var existingPaths = new Array <String> ();
		
		for (path in paths) {
			
			if (FileSystem.exists (path)) {
				
				existingPaths.push (path);
				
			}
			
		}
		
		return existingPaths;
		
	}
	
	
}