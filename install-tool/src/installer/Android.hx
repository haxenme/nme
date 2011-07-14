package installer;

class Android extends Base
{
   override function update()
   {
      var dest = mBuildDir + "/android/project";

      mkdir(dest);

      createIcon(36,36, dest + "/res/drawable-ldpi/icon.png", true);
      createIcon(48,48, dest + "/res/drawable-mdpi/icon.png", true);
      createIcon(72,72, dest + "/res/drawable-hdpi/icon.png", true);


      cp_recurse(NME + "/install-tool/android/template",dest);

      var pkg = mDefines.get("APP_PACKAGE");
      var parts = pkg.split(".");
      var dir = dest + "/src/" + parts.join("/");
      mkdir(dir);
      cp_file(NME + "/install-tool/android/MainActivity.java", dir + "/MainActivity.java");

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/android/haxe");
      cp_recurse(NME + "/install-tool/android/hxml",mBuildDir + "/android/haxe");

      for(ndll in mNDLLs)
         ndll.copy("Android/lib", dest + "/libs/armeabi", true, mVerbose, mAllFiles, "android");
   }

   override function build()
   {
      var ant:String = mDefines.get("ANT_HOME");
      if (ant=="" || ant==null)
      {
         //throw("ANT_HOME not defined.");
         ant = "ant";
      }
      else
         ant += "/bin/ant";

      var dest = mBuildDir + "/android/project";

      addAssets(dest,"android");

      var build = mDefines.exists("KEY_STORE") ? "release" : "debug";
      run(dest, ant, [build] );
   }


   function getAdb()
   {
      var adb = mDefines.get("ANDROID_SDK") + "/tools/adb";
      if (mDefines.exists("windows_host"))
         adb += ".exe";
      if (!neko.FileSystem.exists(adb) )
      {
         adb = mDefines.get("ANDROID_SDK") + "/platform-tools/adb";
         if (mDefines.exists("windows_host"))
            adb += ".exe";
      }
      return adb;
   }

   override function test()
   {
      var build = mDefines.exists("KEY_STORE") ? "release" : "debug";
      var apk = mBuildDir + "/android/project/bin/" + mDefines.get("APP_FILE")+ "-" + build+".apk";
      var adb = getAdb();

      run("", adb, ["install", "-r", apk] );

      var pak = mDefines.get("APP_PACKAGE");
      run("", adb, ["shell", "am start -a android.intent.action.MAIN -n " + pak + "/" +
          pak +".MainActivity" ]);
      run("", adb, ["logcat", "*"] );
   }


   override function uninstall()
   {
      var adb = getAdb();
      var pak = mDefines.get("APP_PACKAGE");

      run("", adb, ["uninstall", pak] );
   }


}


