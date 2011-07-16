package installers;


import neko.io.Path;
import neko.io.Process;
import neko.Lib;
import neko.Sys;


class DesktopInstaller extends InstallerBase {
	
	private var targetName:String;
   var targetDir:String;

   function getVM() : String { throw "getVM not implemented."; return ""; }
	
	override function onCreate()
   {
      if (InstallTool.isMac)
      {
		   targetName = "mac";
         for(asset in assets)
           asset.targetPath = asset.resourceName = asset.flatName;
      }
      else if (InstallTool.isWindows)
		   targetName = "windows";
      else if (InstallTool.isLinux)
		   targetName = "linux";
      else
         throw "Unknown desktop target.";

		targetDir = buildDirectory + "/" + getVM() + "/" + targetName;
   }

   function getBuildDir()
   {
      return targetDir + "/build/";
   }

   function getExeDir()
   {
		if (targetName == "mac")
			return targetDir + "/" + defines.get ("APP_FILE") + ".app/Contents/MacOS/";
			
      return targetDir + "/bin/";
	}

   function getExeName()
   {
		if (targetName == "windows")
			return defines.get("APP_FILE") + ".exe";
			
      return defines.get("APP_FILE");
	}

   function getCwd()
   {
		if (InstallTool.isWindows)
			return ".\\";
			
      return "./";
	}
	
   function getContentDir() : String
   {
		if (targetName=="mac")
			return targetDir + "/" + defines.get ("APP_FILE") + ".app/Contents/Resources/";

		 return targetDir + "/bin/";
   }

   function copyResultTo(inExe:String)
   {
      throw "copyResultTo : Not implemented";
   }
	
	override function build ():Void {

      mkdir(getBuildDir());
      mkdir(getExeDir());

		recursiveCopy (nme + "/install-tool/haxe", targetDir + "/haxe");
		recursiveCopy (nme + "/install-tool/" + getVM() + "/hxml", targetDir + "/haxe");
		
		var hxml:String = targetDir + "/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
      var exe = getExeDir() + "/" + getExeName();

      copyResultTo(exe);
		
		if (!InstallTool.isWindows) {
			
			runCommand ("", "chmod", [ "755", exe ]);
			
		}

		
	}

	
	override function generateContext ():Void {
		
		
		if (defines.exists ("NME_64")) {
			
			targetName += "64";
			
		}

		//compilerFlags.push ("-D " + target);
		compilerFlags.push ("-cp " + targetDir + "/haxe");
		
		super.generateContext ();
	}


	
	override function run ():Void
   {
		runCommand(getExeDir(), getCwd() + getExeName(), []);
	}
	


	
	override function update ():Void {
		
		var exe_dir = getExeDir();
      mkdir(exe_dir);

		recursiveCopy (nme + "/install-tool/haxe", targetDir + "/haxe");
		recursiveCopy (nme + "/install-tool/cpp/hxml", targetDir + "/haxe");
		
	   var system_name = targetName.substr (0, 1).toUpperCase () + targetName.substr (1);

		for (ndll in ndlls) {
			
			var extension:String = ".ndll";
			
			if (ndll.haxelib == "") {
				
				switch (targetName) {
					
					case "windows":
						
						extension = ".dll";
					
					case "linux":
						extension = ".dso";
					
					case "mac":
						
						extension = ".dylib";
					
				}
				
			}
			
			copyIfNewer(ndll.getSourcePath(system_name, ndll.name + extension), exe_dir + ndll.name + extension, verbose);
		}
		
		/*var icon:String = defines.get ("APP_ICON");
		
		if (icon != null && icon != "") {
			
			copyIfNewer (icon, destination + "icon.png", verbose);
			
		}*/
		
   
      var content_dir = getContentDir();
		for (asset in assets) {
			
			mkdir (Path.directory (content_dir + asset.targetPath));
			copyIfNewer (asset.sourcePath, content_dir + asset.targetPath, verbose);
			
		}

     if (targetName=="mac")
        copyFile(nme + "/install-tool/mac/Info.plist", content_dir + "/Info.plist",true);

		
	}
	
	
}
