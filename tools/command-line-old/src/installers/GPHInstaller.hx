package nekonme.install-tool.install-tool.targets;

/**
 * ...
 * @author Joshua Granick
 */

class GPH {

}


 // --- GPH ---------------------------------------------------------------

   function updateGph()
   {
      var dest = mBuildDir + "/gph/game/bin/";
      mContext.CPP_DIR = mBuildDir + "/gph/obj";

      mkdir(dest);

      cp_recurse(NME + "/tools/command-line/haxe",mBuildDir + "/gph/haxe");
      cp_recurse(NME + "/tools/command-line/gph/hxml",mBuildDir + "/gph/haxe");
      cp_file(NME + "/tools/command-line/gph/game.ini",mBuildDir + "/gph/game/"  + mDefines.get("APP_FILE") + ".ini" );
      var boot = mDebug ? "Boot-debug.gpe" : "Boot-release.gpe";
      cp_file(NME + "/tools/command-line/gph/" + boot,mBuildDir + "/gph/game/"  + mDefines.get("APP_FILE") + "/Boot.gpe" );

      for(ndll in mNDLLs)
         ndll.copy("GPH/", dest, true, InstallTool.verbose, mAllFiles, "gph");

      var icon = mDefines.get("APP_ICON");
      if (icon!="")
      {
         copyIfNewer(icon, dest + "/icon.png", mAllFiles);
      }

      addAssets(dest,"cpp");
   }

   function buildGph()
   {
      var file = mDefines.get("APP_FILE");
      var dest = mBuildDir + "/gph/game/" + file + "/" + file + ".gpe";
      var gpe = mDebug ? "ApplicationMain-debug.gpe" : "ApplicationMain.gpe";
      copyIfNewer(mBuildDir+"/gph/bin/" + gpe, dest, mAllFiles );
   }

   function runGph()
   {
      if (!mDefines.exists("DRIVE"))
         throw "Please specify DRIVE=f:/ or similar on the command line.";
      var drive = mDefines.get("DRIVE");
      if (!neko.FileSystem.exists(drive + "/game"))
         throw "Drive " + drive + " does not appear to be a Caanoo drive.";
      cp_recurse(mBuildDir + "/gph/game", drive + "/game",false);

   }
