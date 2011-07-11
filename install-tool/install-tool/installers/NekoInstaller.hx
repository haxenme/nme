package nekonme.install-tool.install-tool.targets;

/**
 * ...
 * @author Joshua Granick
 */

class Neko {

	public function new() {
		
	}
	
}



 // --- Neko -----------------------------------------------------------

   function updateNeko()
   {
      var dest = mBuildDir + "/neko/" + mOS + "/";
      var dot_n = dest+"/"+mDefines.get("APP_FILE")+".n";
      mContext.NEKO_FILE = dot_n;

      mkdir(dest);

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/neko/haxe");
      cp_recurse(NME + "/install-tool/neko/hxml",mBuildDir + "/neko/haxe");

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
         InstallTool.copyIfNewer(src,dest + "/nekoapi.ndll",mAllFiles,mVerbose);
      }

      var icon = mDefines.get("APP_ICON");
      if (icon!="" && icon!=null)
         copyIfNewer(icon, dest + "/icon.png",mAllFiles,mVerbose);

      var neko = getNeko();
      if (mOS=="Windows")
      {
         copyIfNewer(neko + "gc.dll", dest + "/gc.dll",mAllFiles,mVerbose);
         copyIfNewer(neko + "neko.dll", dest + "/neko.dll",mAllFiles,mVerbose);
      }

      addAssets(dest,"neko");
   }


   function buildNeko()
   {
      var dest = mBuildDir + "/neko/" + neko.Sys.systemName()  + "/";
      run(dest,"nekotools",["boot",mDefines.get("APP_FILE")+".n"]);
   }

   function runNeko()
   {
      var dest = mBuildDir + "/neko/" + neko.Sys.systemName() + "/";

      run(dest, "neko" , [ mDefines.get("APP_FILE") + ".n"  ] );
   }
