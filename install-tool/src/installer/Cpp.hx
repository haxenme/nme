package installer;


class Cpp extends Base
{
   function getCppContentDest()
   {
      return isMac() ? getCppDest() + "/Contents" : getCppDest();
   }

   function getCppDest()
   {
      if (isMac())
         return mBuildDir + "/cpp/" + mOS + "/" + mDefines.get("APP_FILE") + ".app";

      return mBuildDir + "/cpp/" + mOS + "/" + mDefines.get("APP_FILE");
   }

   override function update()
   {
      mInstallBase = mBuildDir + "/cpp/" + mOS + "/";

      var dest = getCppDest();
      mContext.CPP_DIR = mBuildDir + "/cpp/bin";


      var content_dest = getCppContentDest();
      var exe_dest = content_dest + (isMac() ? "/MacOS" : "" );
      mkdir(exe_dest);

      for(ndll in mNDLLs)
         ndll.copy( mOS + "/", exe_dest, true, mVerbose, mAllFiles );

      if (isMac())
      {
         cp_file(NME + "/install-tool/mac/Info.plist", content_dest + "/Info.plist",true);

         var resource_dest = content_dest + "/Resources";
         mkdir(resource_dest);

         createMacIcon(resource_dest);

         addAssets(resource_dest,"cpp");
      }
      else
      {
         if (createIcon(32,32, mInstallBase + "/icon.png",false,"icon.png"))
            mContext.WIN_ICON = "icon.png";

         addAssets(content_dest,"cpp");
      }

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/cpp/haxe");
      cp_recurse(NME + "/install-tool/cpp/hxml",mBuildDir + "/cpp/haxe");
   }

   override function build()
   {
      var ext = getExt();
      var exe_dest = isMac() ? getCppDest() + "/Contents/MacOS" : getCppDest();
      mkdir(exe_dest);

      var file = exe_dest + "/" + mDefines.get("APP_FILE")+ ext;
      var dbg = mDebug ? "-debug" : "";
      copyIfNewer(mBuildDir+"/cpp/bin/ApplicationMain"+dbg+ext, file, mAllFiles,mVerbose);
      if (isMac() || isLinux())
         run("","chmod", [ "755", file ]);
      if (isWindows())
         setWindowsIcon(getCppDest(), file);
   }

   override function test()
   {
      var exe_dest = isMac() ? getCppDest() + "/Contents/MacOS" : getCppDest();
      run(exe_dest, dotSlash() + mDefines.get("APP_FILE"), [] );
   }

}


