package installer;


class Gph extends Base
{
   override function update()
   {
      var dest = mBuildDir + "/gph/game/" + mDefines.get("APP_FILE") + "/";
      mContext.CPP_DIR = mBuildDir + "/gph/bin";

      mkdir(dest);

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/gph/haxe");
      cp_recurse(NME + "/install-tool/gph/hxml",mBuildDir + "/gph/haxe");
      cp_file(NME + "/install-tool/gph/game.ini",mBuildDir + "/gph/game/"  + mDefines.get("APP_FILE") + ".ini" );
      var boot = mDebug ? "Boot-debug.gpe" : "Boot-release.gpe";
      cp_file(NME + "/install-tool/gph/" + boot,mBuildDir + "/gph/game/"  + mDefines.get("APP_FILE") + "/Boot.gpe" );

      for(ndll in mNDLLs)
         ndll.copy("GPH/", dest, true, mVerbose, mAllFiles, "gph");


      createIcon(32,32, dest + "/icon.png",true);

      addAssets(dest,"cpp");
   }

   override function build()
   {
      var file = mDefines.get("APP_FILE");
      var dest = mBuildDir + "/gph/game/" + file + "/" + file + ".gpe";
      var gpe = mDebug ? "ApplicationMain-debug.gpe" : "ApplicationMain.gpe";
      copyIfNewer(mBuildDir+"/gph/bin/" + gpe, dest, mAllFiles, mVerbose);
   }

   override function test()
   {
      if (!mDefines.exists("DRIVE"))
         throw "Please specify DRIVE=f:/ or similar on the command line.";
      var drive = mDefines.get("DRIVE");
      if (!neko.FileSystem.exists(drive + "/game"))
         throw "Drive " + drive + " does not appear to be a Caanoo drive.";
      cp_recurse(mBuildDir + "/gph/game", drive + "/game",false);

   }



}
