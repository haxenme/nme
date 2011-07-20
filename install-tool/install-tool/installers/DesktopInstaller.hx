package installers;


import neko.io.Path;
import neko.io.Process;
import neko.Lib;
import neko.Sys;
import data.Asset;


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
      return targetDir + "/obj";
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

      updateIcon();
	}


	
	override function run ():Void
   {
		runCommand(getExeDir(), getCwd() + getExeName(), []);
	}
	

   function updateIcon()
   {
      if (!InstallTool.isMac)
      {
         var icon_name = icons.findIcon(32,32);
         if (icon_name=="")
         {
             var tmp_name = targetDir + "/haxe/icon.png";
             if (icons.updateIcon(32,32,tmp_name))
                icon_name = tmp_name;
         }
         if (icon_name!="")
         {
            assets.push( new data.Asset(icon_name, "icon.png", Asset.TYPE_IMAGE, "icon.png", "1") );
            context.WIN_ICON = "icon.png";
         }
      }
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
				
				if (InstallTool.isWindows)
					extension = ".dll";
            else if (InstallTool.isLinux)
					extension = ".dso";
				else if (InstallTool.isMac)
						extension = ".dylib";
				
			}
			
			copyIfNewer(ndll.getSourcePath(system_name, ndll.name + extension), exe_dir + ndll.name + extension);
		}


      var content_dir = getContentDir();
		for (asset in assets) {
			
			mkdir (Path.directory (content_dir + asset.targetPath));
			copyIfNewer (asset.sourcePath, content_dir + asset.targetPath );
			
		}

     if (InstallTool.isMac)
     {
        var filename =  icons.createMacIcon(content_dir);
        if (addFile(filename))
           context.HAS_ICON = true;
          
        copyFile(nme + "/install-tool/mac/Info.plist", targetDir + "/" + defines.get ("APP_FILE") + ".app/Contents/Info.plist",true);
     }
	}
	
	
}
