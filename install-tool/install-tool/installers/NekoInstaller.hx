package installers;


import neko.io.Path;
import neko.io.Process;
import neko.Lib;
import neko.Sys;


class NekoInstaller extends DesktopInstaller {
	
   override function getVM() { return "neko"; }

   override function copyResultTo(inExe:String)
   {
      var extension = (targetName=="windows") ? ".exe" : "";

      runCommand( getBuildDir(),"nekotools",["boot","ApplicationMain.n"]);

      copyIfNewer ( getBuildDir() + "/ApplicationMain" + extension, inExe );
   }


	override function generateContext ():Void {
	   super.generateContext ();
		
		context.NEKO_FILE = getBuildDir() + "/ApplicationMain.n";
   }



}


