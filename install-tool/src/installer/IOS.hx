package installer;

class IOS extends Base
{
   override function update()
   {
      var dest = mBuildDir + "/iphone/";

      mkdir(dest);

      var has_icon = true;
      for(i in 0...4)
      {
         var iname = ["Icon.png", "Icon@2x.png", "Icon-72.png", "Icon-Small.png" ][i];
         var size = [57,114,72,50][i];
         var bmp = getIconBitmap(size,size,"",{a:255,rgb:0} );
         if (bmp!=null)
         {
            var name = dest + "/" + iname;
            var bytes = bmp.encode("PNG",0.95);
            bytes.writeFile(name);
            mAllFiles.push(name);
         }
         else
            has_icon = false;
      }

      mContext.HAS_ICON = has_icon;

      cp_recurse(NME + "/install-tool/iphone/haxe", dest + "/haxe");

      var proj = mDefines.get("APP_FILE");

      cp_recurse(NME + "/install-tool/iphone/Classes", dest+"Classes");

      cp_recurse(NME + "/install-tool/iphone/PROJ.xcodeproj", dest + proj + ".xcodeproj");

      cp_file(NME + "/install-tool/iphone/PROJ-Info.plist", dest + proj + "-Info.plist");

      var lib = dest + "lib/";
      mkdir(lib);

      for(ndll in mNDLLs)
      {
         ndll.copy("iPhone/", lib, true, mVerbose, mAllFiles, "iphoneos");
         ndll.copy("iPhone/", lib, true, mVerbose, mAllFiles, "iphonesim");
      }

      addAssets(dest,"iphone");
   }

   override function build()
   {
/*
      var file = mDefines.get("APP_FILE");
      var dest = mBuildDir + "/gph/game/" + file + "/" + file + ".gpe";
      var gpe = mDebug ? "ApplicationMain-debug.gpe" : "ApplicationMain.gpe";
      copyIfNewer(mBuildDir+"/gph/bin/" + gpe, dest, mVerbose);
*/
   }

   override function test()
   {
/*
      if (!mDefines.exists("DRIVE"))
         throw "Please specify DRIVE=f:/ or similar on the command line.";
      var drive = mDefines.get("DRIVE");
      if (!neko.FileSystem.exists(drive + "/game"))
         throw "Drive " + drive + " does not appear to be a Caanoo drive.";
      cp_recurse(mBuildDir + "/gph/game", drive + "/game",false);
*/
   }


}


