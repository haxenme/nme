package installers;


import neko.io.Path;
import neko.io.Process;
import neko.Lib;
import neko.Sys;


class CPPInstaller extends DesktopInstaller {
	
   override function getVM() { return "cpp"; }

   override function copyResultTo(inExe:String)
   {
      var dbg = debug ? "-debug" : "";
      var extension = (targetName=="windows") ? ".exe" : "";

      copyIfNewer ( getBuildDir() + "/ApplicationMain" + dbg + extension, inExe );
   }

	override function generateContext ():Void {
	   super.generateContext ();
		
		context.CPP_DIR = getBuildDir();
   }


}
