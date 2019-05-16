package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;


class AndroidPlatform extends Platform
{
   var buildV5:Bool;
   var buildV7:Bool;
   var build64:Bool;
   var buildX86:Bool;
   var gradle:Bool;


   public function new(inProject:NMEProject)
   {
      super(inProject);

     if (project.hasDef("androidBilling"))
     {
        CommandLineTools.gradle = true;
        project.haxedefs.set("gradle", "1");
        project.haxedefs.set("androidBilling", "1");
     }


      buildV5 = buildV7 = build64 = buildX86 = false;

      gradle = CommandLineTools.gradle;
      if (gradle)
      {
         Log.verbose("Using gradle build system");
         PathHelper.mkdir(getAppDir());
      }

      var archs = project.architectures;
      var isSim =  project.targetFlags.exists("androidsim");
      if (isSim)
         ArrayHelper.addUnique(archs, Architecture.X86);
      // Default to V7 now...
      if (archs.length<1) {
         if(project.certificate == null) {
            archs.push(Architecture.ARMV7);  
         }
         else {
            archs.push(Architecture.ARMV7);
            archs.push(Architecture.ARM64);
            archs.push(Architecture.X86);
         }
      }
      Log.verbose("Valid archs :" + archs );

      if (!isSim)
      {
         buildV5 = hasArch(ARMV5);
         buildV7 = hasArch(ARMV7);
         build64 = hasArch(ARM64);
      }
      buildX86 = hasArch(X86);


      var libDir = getOutputLibDir();
      if (!buildV5)
         PathHelper.removeDirectory(libDir + "/armeabi");
      if (!buildV7)
         PathHelper.removeDirectory(libDir + "/armeabi-v7a");
      if (!build64)
         PathHelper.removeDirectory(libDir + "/arm64-v8a");
      if (!buildX86)
         PathHelper.removeDirectory(libDir + "/x86");

      setupAdb();

      if (project.environment.exists("JAVA_HOME")) 
         Sys.putEnv("JAVA_HOME", project.environment.get("JAVA_HOME"));

      project.haxeflags.push('-cpp $haxeDir/cpp');

      for(asset in project.assets) 
      {
         if (!asset.embed)
         {
            var targetPath = "";
            switch(asset.type) 
            {
               case SOUND, MUSIC:
                  asset.resourceName = asset.id;
                  asset.targetPath =  '${decideAudioFolder()}/${asset.flatName}.${Path.extension(asset.targetPath)}';

               default:
                  asset.resourceName = asset.flatName;
                  asset.targetPath = '${decideAssetsFolder()}/${asset.resourceName}';
            }
         }
      }
   }
      
   private function decideAudioFolder() {
      if(gradle)
         return 'app/src/main/res/raw';
      return 'res/raw';
   }

   private function decideAssetsFolder() {
      if(gradle)
         return 'app/src/main/assets';
      return 'assets';
   }

   public function getAppDir()
   {
      return gradle ? getOutputDir() + "/app/src/main"  : getOutputDir();
   }


   public function getOutputLibDir()
   {
      return gradle ? getOutputDir() + "/app/src/main/jniLibs"  : getOutputDir() + "/libs";
   }



   override public function getPlatformDir() : String
   {
      return "android";
   }

   override public function getBinName() : String { return "Android"; }
   override public function getNdllExt() : String { return ".so"; }
   override public function getNdllPrefix() : String { return "lib"; }




   override public function runHaxe()
   {
      var args = project.debug ? ['$haxeDir/build.hxml',"-debug","-D", "android"] :
                                 ['$haxeDir/build.hxml', "-D", "android" ];

      if (buildV5)
         runHaxeWithArgs(args);

      if (buildV7)
         runHaxeWithArgs(args.concat(["-D", "HXCPP_ARMV7"]) );
      
      if (build64)
         runHaxeWithArgs(args.concat(["-D", "HXCPP_ARM64"]) );

      if (buildX86)
         runHaxeWithArgs(args.concat(["-D", "HXCPP_X86"]) );
   }


   override public function copyBinary():Void 
   {
      var dbg = project.debug ? "-debug" : "";

      if (buildV5)
         FileHelper.copyIfNewer(haxeDir + "/cpp/libApplicationMain" + dbg + ".so",
                getOutputLibDir() + "/armeabi/libApplicationMain.so");

      if (buildV7)
         FileHelper.copyIfNewer(haxeDir + "/cpp/libApplicationMain" + dbg + "-v7.so",
                getOutputLibDir() + "/armeabi-v7a/libApplicationMain.so" );

      if (build64)
           FileHelper.copyIfNewer(haxeDir + "/cpp/libApplicationMain" + dbg + "-64.so",
           getOutputLibDir() + "/arm64-v8a/libApplicationMain.so" );
      
      if (buildX86)
         FileHelper.copyIfNewer(haxeDir + "/cpp/libApplicationMain" + dbg + "-x86.so",
                getOutputLibDir() + "/x86/libApplicationMain.so" );
   }


   override function generateContext(context:Dynamic) : Void
   {
      context.ANDROID_INSTALL_LOCATION = project.androidConfig.installLocation;
      context.DEBUGGABLE = project.debug;

      var staticNme = project.isStaticNme();
      for(ndll in project.ndlls)
         if (ndll.name=="nme" && ndll.isStatic)
            staticNme = true;
      context.STATIC_NME = staticNme;

      context.appHeader = project.androidConfig.appHeader;
      context.appActivity = project.androidConfig.appActivity;
      context.appIntent = project.androidConfig.appIntent;
      context.appPermission = project.androidConfig.appPermission;
      context.appFeature = project.androidConfig.appFeature;
      if (project.hasDef("androidBilling"))
         context.ANDROID_BILLING=1;


      // Will not install on devices less than this ....
      context.ANDROID_MIN_API_LEVEL = project.androidConfig.minApiLevel;

      // Features we have tested and will use if available
      context.ANDROID_TARGET_API_LEVEL = project.androidConfig.targetApiLevel==null ?
           getMaxApiLevel(project.androidConfig.minApiLevel) : project.androidConfig.targetApiLevel;

      if (context.ANDROID_TARGET_API_LEVEL < context.ANDROID_MIN_API_LEVEL)
         context.ANDROID_TARGET_API_LEVEL = context.ANDROID_MIN_API_LEVEL;

      // SDK to use for building, that we have installed
      context.ANDROID_BUILD_API_LEVEL = getMaxApiLevel(project.androidConfig.minApiLevel);
      context.ANDROID_TARGET_SDK_VERSION = getMaxApiLevel(project.androidConfig.minApiLevel);

      context.GAME_ACTIVITY_BASE = project.androidConfig.gameActivityBase;

      var extensions = new Array<String>();
      for( k in project.androidConfig.extensions.keys())
         extensions.push(k);
      context.ANDROID_EXTENSIONS =extensions;

      context.ANDROID_SDK = StringTools.replace(project.environment.get("ANDROID_SDK"),"\\","/");
      
      if(gradle)
         setGradleLibraries();
      else
         setAntLibraries();
   }

   private function setAntLibraries() {
      context.ANDROID_LIBRARY_PROJECTS = [];
      var idx = 1;
      var extensionApi = "deps/extension-api";
      context.ANDROID_LIBRARY_PROJECTS.push( {index:idx++, path:extensionApi} );
      for(k in project.dependencies.keys())
      {
         var lib = project.dependencies.get(k);
         if (lib.isAndroidProject() && getAndroidProject(lib)!=extensionApi)
         {
            var proj = getAndroidProject(lib);
            context.ANDROID_LIBRARY_PROJECTS.push( {index:idx++, path:proj} );
         }
      }
   }
   
   private function setGradleLibraries() {
      context.ANDROID_LIBRARY_PROJECTS = [{name:'extension-api'}];
      for(k in project.dependencies.keys()) {
         var lib = project.dependencies.get(k);
         if (lib.isAndroidProject()) {
            context.ANDROID_LIBRARY_PROJECTS.push( {name:lib.name} );
         }
      }
   }

   public function getAndroidProject(inDep:Dependency):String
   {
      return "deps/" + inDep.makeUniqueName();
   }


   public function getMaxApiLevel(inMinimum:Int) : Int
   { 
      var result = inMinimum;
      if (project.environment.exists("ANDROID_SDK"))
         try
         {
            var dir = project.environment.get("ANDROID_SDK");
            for(file in FileSystem.readDirectory(dir+"/platforms"))
            {
               if (file.substr(0,8)=="android-")
               {
                  var val = Std.parseInt(file.substr(8));
                  if (val>result)
                     result = val;
               }
            }
         } catch(e:Dynamic){}

     return result;
   }


   public function androidBuild(outputDir:String):Void 
   {
      if (project.environment.exists("ANDROID_SDK")) 
         Sys.putEnv("ANDROID_SDK", project.environment.get("ANDROID_SDK"));

      if (gradle)
      {
         var assemble = (project.certificate != null) ? "assembleRelease" : "assembleDebug";

         if(PlatformHelper.hostPlatform==Platform.MAC)
            ProcessHelper.runCommand(outputDir, 'chmod', ['+x', './gradlew']);
          
         var exe = PlatformHelper.hostPlatform==Platform.WINDOWS ? "./gradlew.bat" : "./gradlew";
         ProcessHelper.runCommand(outputDir, exe, [ assemble ]);
      }
      else
      {
         var build = "debug";
         if (project.certificate != null) 
            build = "release";


         var ant = project.environment.get("ANT_HOME");
         if (ant == null || ant == "") 
            ant = "ant";
         else
            ant += "/bin/ant";


         // Fix bug in Android build system, force compile
         var buildProperties = outputDir + "/bin/build.prop";
         if (FileSystem.exists(buildProperties)) 
            FileSystem.deleteFile(buildProperties);

         ProcessHelper.runCommand(outputDir, ant, [ "-v", build ]);
      }
   }

   override public function buildPackage():Void 
   {
      androidBuild( getOutputDir() );
   }

   override public function install():Void 
   {
      var targetPath = "";
     
      var outputDir = getOutputDir();
      if (gradle)
      {
         var build = (project.certificate != null) ? "release" : "debug";

         targetPath = '${FileSystem.fullPath(outputDir)}/app/build/outputs/apk/${build}/app-${build}.apk';
      }
      else
      {
         var build = "debug";
         if (project.certificate != null) 
            build = "release";

         targetPath = FileSystem.fullPath(outputDir) + "/bin/" + project.app.file + "-" + build + ".apk";
      }


      // Apparently an exit code is too much to ask...
      // ProcessHelper.runCommand("", adbName, adbFlags.concat([ "install", "-r", targetPath ]) );
      try
      {
         var lines = ProcessHelper.getOutput(adbName,adbFlags.concat([ "install", "-r", targetPath ]), Log.mVerbose);
         var failure = ~/Failure/;
         for(line in lines)
            if (failure.match(line))
               Log.error("Failed to install apk:"  + line);
      }
      catch(e:Dynamic)
      {
         Log.error("Could not run adb install " + e);
      }
   }

   override public function run(arguments:Array<String>):Void 
   {
      var activityName = project.app.packageName + "/" + project.app.packageName + ".MainActivity";

      ProcessHelper.runCommand("", adbName, adbFlags.concat([ "logcat", "-c" ]));
      ProcessHelper.runCommand("", adbName, adbFlags.concat([ "shell", "am", "start", "-a", "android.intent.action.MAIN", "-n", activityName ]));

   }

   override public function trace():Void 
   {
      ProcessHelper.runCommand("", adbName, adbFlags.concat([ "logcat" ]));
   }

   override public function uninstall():Void 
   {
      ProcessHelper.runCommand("", adbName, adbFlags.concat([ "uninstall", project.app.packageName ]));
   }

   override public function updateLibs()
   {
      var libDir = getOutputLibDir();
      if (buildV5)
         updateLibArch( libDir + "/armeabi", "" );
      if (buildV7)
         updateLibArch( libDir + "/armeabi-v7a", "-v7" );
      if (build64)
         updateLibArch( libDir + "/arm64-v8a", "-64" );
      if (buildX86)
         updateLibArch( libDir + "/x86", "-x86" );
   }


   override public function getOutputExtra()
   {
      return gradle ? "android/PROJ-gradle" : "android/PROJ";
   }

   function addV4CompatLib(inDest:String)
   {
      var lib = project.environment.get("ANDROID_SDK") +
         "/extras/android/compatibility/v4/android-support-v4.jar";
      if (!FileSystem.exists(lib))
         lib = project.environment.get("ANDROID_SDK") +
            "/extras/android/support/v4/android-support-v4.jar";
      if (!FileSystem.exists(lib))
      {
         var dir = project.environment.get("ANDROID_SDK") +
               "/extras/android/m2repository/com/android/support/support-v4";
         if (FileSystem.exists(dir))
         {
            var versionMatch = ~/^(\d)+\.(\d+)\.(\d+)$/;
            var best = 0;
            var bestFile:String = null;
            for(file in FileSystem.readDirectory(dir))
            {
               if (versionMatch.match(file))
               {
                  var v0 = Std.parseInt(versionMatch.matched(1));
                  var v1 = Std.parseInt(versionMatch.matched(2));
                  var v2 = Std.parseInt(versionMatch.matched(3));
                  var v = v0*10000 + v1*100 + v0;
                  if (v>best && FileSystem.exists('$dir/$file/support-v4-$file-sources.jar' ) )
                  {
                     best = v0;
                     bestFile = file;
                  }
               }
            }
            if (bestFile!=null)
            {
               lib = '$dir/$bestFile/support-v4-$bestFile-sources.jar';
               Log.verbose('Found support-v4 in $lib');
            }
         }
      }

/*
      if (!FileSystem.exists(lib))
      {
         lib = CommandLineTools.nme + "/tools/nme/bin/android-support-v4.jar";
      }
*/


      if (FileSystem.exists(lib))
      {
         Log.verbose("copy to " + inDest + "/android-support-v4.jar");
         FileHelper.copyIfNewer(lib, inDest + "/android-support-v4.jar");
      }
      else
         Log.error("Could not find " + lib + " - use the SDK Manager to add the dependency" );
   }

   override public function updateOutputDir():Void 
   {
      super.updateOutputDir();

      var destination = getAppDir();
      PathHelper.mkdir(destination + "/res/drawable-ldpi/");
      PathHelper.mkdir(destination + "/res/drawable-mdpi/");
      PathHelper.mkdir(destination + "/res/drawable-hdpi/");
      PathHelper.mkdir(destination + "/res/drawable-xhdpi/");
      PathHelper.mkdir(destination + "/res/drawable-xxhdpi/");
      PathHelper.mkdir(destination + "/res/drawable-xxxhdpi/");

      var iconTypes = [ "ldpi", "mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi" ];
      var iconSizes = [ 36, 48, 72, 96, 144, 192 ];

      for(i in 0...iconTypes.length) 
      {
         if (IconHelper.createIcon(project.icons, iconSizes[i], iconSizes[i], destination + "/res/drawable-" + iconTypes[i] + "/icon.png")) 
            context.HAS_ICON = true;
      }

      IconHelper.createIcon(project.banners!=null ? project.banners : project.icons, 732, 412,
         destination + "/res/drawable-xhdpi/ouya_icon.png");

      if (project.banners.length>0)
      {
         // TV banner icon
         if (IconHelper.createIcon(project.banners, 320, 180, destination + "/res/drawable-xhdpi/banner.png")) 
           context.HAS_BANNER = true;
      }
       

      var packageDirectory = project.app.packageName;
      var srcPath = gradle ? "/java" : "/src";
      packageDirectory = destination + srcPath + "/" + packageDirectory.split(".").join("/");
      PathHelper.mkdir(packageDirectory);
      copyTemplate("android/MainActivity.java", packageDirectory + "/MainActivity.java");

      if (!gradle)
      {
         var movedFiles = [ "src/org/haxe/nme/HaxeObject.java",
                            "src/org/haxe/nme/Value.java",
                            "src/org/haxe/nme/NME.java",
                            "bin/classes/org/haxe/nme/HaxeObject.class",
                            "bin/classes/org/haxe/nme/Value.class",
                            "bin/classes/org/haxe/nme/NME.class" ];
         for(moved in movedFiles)
         {
            var file = destination + "/" + moved;
            if (FileSystem.exists(file))
            {
               Log.verbose("Remove legacy file " + file);
               FileSystem.deleteFile(file);
            }
         }
      }

      var jarDir = getAppDir()+"/deps/extension-api/libs";
      for(javaPath in project.javaPaths) 
      {
         try 
         {
            if (FileSystem.isDirectory(javaPath)) 
               FileHelper.recursiveCopy(javaPath, destination + srcPath, context, true);
            else
            {
               if (Path.extension(javaPath) == "jar") 
                  FileHelper.copyIfNewer(javaPath, jarDir + "/" + Path.withoutDirectory(javaPath));
               else
                  FileHelper.copyIfNewer(javaPath, destination + srcPath + Path.withoutDirectory(javaPath));
            }
         } catch(e:Dynamic) {}
      }

      //if (project.androidConfig.minApiLevel < 14)
      if (project.androidConfig.addV4Compat && !gradle)
         addV4CompatLib(jarDir);

      if (gradle) {
         copyTemplateDir( "android/extension-api", '${getOutputDir()}/extension-api');
         copyTemplateDir( "android/java", '${getOutputDir()}/app/src/main/java');
      }
      else {
         copyTemplateDir( "android/extension-api", '${getOutputDir()}/deps/extension-api');
         copyTemplateDir( "android/java", '${getOutputDir()}/src');
      }
       
      for(k in project.dependencies.keys())
      {
         var lib = project.dependencies.get(k);
         if (gradle) {
              var libPath = '${getOutputDir()}/${lib.makeUniqueName()}';
              FileHelper.recursiveCopy( lib.getFilename(), libPath, context, true);
         }
         else if (lib.isAndroidProject())
         {
               FileHelper.recursiveCopy( lib.getFilename(), getAppDir()+"/"+getAndroidProject(lib), context, true);
         }
      }
   }

}
