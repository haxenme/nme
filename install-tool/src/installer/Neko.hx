package installer;

class Neko extends Base
{

   override function update()
   {
      var dest = mBuildDir + "/neko/" + mOS + "/";
      var dot_n = dest+"/"+mDefines.get("APP_FILE")+".n";
      mContext.NEKO_FILE = dot_n;

      mkdir(dest);

      var needsNekoApi = false;
      for(ndll in mNDLLs)
      {
         ndll.copy( mOS + "/", dest, false, mVerbose, mAllFiles );
         if (ndll.needsNekoApi)
            needsNekoApi = true;
      }
      if (needsNekoApi)
      {
         var src = NDLL.getHaxelib("hxcpp") + "/bin/" + mOS + "/nekoapi.ndll";
         copyIfNewer(src,dest + "/nekoapi.ndll",mAllFiles,mVerbose);
      }

      if (createIcon(32,32,mBuildDir + "/neko/icon.png", false, "icon.png"))
         mContext.WIN_ICON = "icon.png";

      var neko = InstallTool.getNeko();
      if (mOS=="Windows")
      {
         copyIfNewer(neko + "gc.dll", dest + "/gc.dll",mAllFiles,mVerbose);
         copyIfNewer(neko + "neko.dll", dest + "/neko.dll",mAllFiles,mVerbose);
      }

      addAssets(dest,"neko");

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/neko/haxe");
      cp_recurse(NME + "/install-tool/neko/hxml",mBuildDir + "/neko/haxe");
   }


   override function build()
   {
      var dest = mBuildDir + "/neko/" + neko.Sys.systemName()  + "/";
      run(dest,"nekotools",["boot",mDefines.get("APP_FILE")+".n"]);

      if (isWindows())
         setWindowsIcon(dest, dest+"/" + mDefines.get("APP_FILE")+".exe");
   }

   override function test()
   {
      var dest = mBuildDir + "/neko/" + neko.Sys.systemName() + "/";

      run(dest, "neko" , [ mDefines.get("APP_FILE") + ".n"  ] );
   }


}
