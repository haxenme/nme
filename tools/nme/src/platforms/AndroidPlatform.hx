package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;


class AndroidPlatform extends Platform
{
   var buildV5:Bool;
   var buildV7:Bool;
   var buildX86:Bool;


   public function new(inProject:NMEProject)
   {
      super(inProject);

      buildV5 = buildV7 = buildX86 = false;

      var archs = project.architectures;
      var isSim =  project.targetFlags.exists("androidsim");
      if (isSim)
         ArrayHelper.addUnique(archs, Architecture.X86);
      if (archs.length<1)
         archs.push(Architecture.ARMV5);
      Log.verbose("Valid archs :" + archs );

      if (!isSim)
      {
         buildV5 = hasArch(ARMV5);
         buildV7 = hasArch(ARMV7);
      }
      buildX86 = hasArch(X86);


      if (!buildV5)
         PathHelper.removeDirectory(getOutputDir() + "/libs/armeabi");
      if (!buildV7)
         PathHelper.removeDirectory(getOutputDir() + "/libs/armeabi-v7a");
      if (!buildX86)
         PathHelper.removeDirectory(getOutputDir() + "/libs/x86");

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
                  asset.targetPath =  "res/raw/" + asset.flatName + "." + Path.extension(asset.targetPath);

               default:
                  asset.resourceName = asset.flatName;
                  asset.targetPath = "assets/" + asset.resourceName;
            }
         }
      }
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
         ProcessHelper.runCommand("", "haxe", args);

      if (buildV7)
         ProcessHelper.runCommand("", "haxe", args.concat(["-D", "HXCPP_ARMV7"]) );

      if (buildX86)
         ProcessHelper.runCommand("", "haxe", args.concat(["-D", "HXCPP_X86"]) );
   }


   override public function copyBinary():Void 
   {
      var dbg = project.debug ? "-debug" : "";

      if (buildV5)
         FileHelper.copyIfNewer(haxeDir + "/cpp/libApplicationMain" + dbg + ".so",
                getOutputDir() + "/libs/armeabi/libApplicationMain.so");

      if (buildV7)
         FileHelper.copyIfNewer(haxeDir + "/cpp/libApplicationMain" + dbg + "-v7.so",
                getOutputDir() + "/libs/armeabi-v7a/libApplicationMain.so" );

      if (buildX86)
         FileHelper.copyIfNewer(haxeDir + "/cpp/libApplicationMain" + dbg + "-x86.so",
                getOutputDir() + "/libs/x86/libApplicationMain.so" );
   }


   override function generateContext(context:Dynamic) : Void
   {
      context.ANDROID_INSTALL_LOCATION = project.androidConfig.installLocation;
      context.DEBUGGABLE = project.debug;

      var staticNme = false;
      for(ndll in project.ndlls)
         if (ndll.name=="nme" && ndll.isStatic)
            staticNme = true;
      context.STATIC_NME = staticNme;

      context.appHeader = project.androidConfig.appHeader;
      context.appActivity = project.androidConfig.appActivity;
      context.appIntent = project.androidConfig.appIntent;
      context.appPermission = project.androidConfig.appPermission;
      context.appFeature = project.androidConfig.appFeature;


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

      context.ANDROID_LIBRARY_PROJECTS = [];
      var idx = 1;
      var extensionApi = "deps/extension-api";
      context.ANDROID_LIBRARY_PROJECTS.push( {index:idx++, path:extensionApi} );
      for(k in project.dependencies.keys())
      {
         var lib = project.dependencies.get(k);
         if (lib.isAndroidProject() && getAndroidProject(lib)!=extensionApi)
            context.ANDROID_LIBRARY_PROJECTS.push( {index:idx++, path:getAndroidProject(lib)} );
      }
   }

   public function getAndroidProject(inDep:Dependency)
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

      var ant = project.environment.get("ANT_HOME");
      if (ant == null || ant == "") 
         ant = "ant";
      else
         ant += "/bin/ant";

      var build = "debug";
      if (project.certificate != null) 
         build = "release";

      // Fix bug in Android build system, force compile
      var buildProperties = outputDir + "/bin/build.prop";
      if (FileSystem.exists(buildProperties)) 
         FileSystem.deleteFile(buildProperties);

      ProcessHelper.runCommand(outputDir, ant, [ build ]);
   }

   override public function buildPackage():Void 
   {
      androidBuild( getOutputDir() );
   }

   override public function install():Void 
   {
      var build = "debug";
      if (project.certificate != null) 
         build = "release";

      var outputDir = getOutputDir();
      var targetPath = FileSystem.fullPath(outputDir) + "/bin/" + project.app.file + "-" + build + ".apk";

      ProcessHelper.runCommand("", adbName, adbFlags.concat([ "install", "-r", targetPath ]) );
   }

   override public function run(arguments:Array<String>):Void 
   {
      var activityName = project.app.packageName + "/" + project.app.packageName + ".MainActivity";

      ProcessHelper.runCommand("", adbName, adbFlags.concat([ "shell", "am", "start", "-a", "android.intent.action.MAIN", "-n", activityName ]));

   }

   override public function trace():Void 
   {
      ProcessHelper.runCommand("", adbName, adbFlags.concat([ "logcat", "-c" ]));
      ProcessHelper.runCommand("", adbName, adbFlags.concat([ "logcat" ]));
   }

   override public function uninstall():Void 
   {
      ProcessHelper.runCommand("", adbName, adbFlags.concat([ "uninstall", project.app.packageName ]));
   }

   override public function updateLibs()
   {
      if (buildV5)
         updateLibArch( getOutputDir() + "/libs/armeabi", "" );
      if (buildV7)
         updateLibArch( getOutputDir() + "/libs/armeabi-v7a", "-v7" );
      if (buildX86)
         updateLibArch( getOutputDir() + "/libs/x86", "-x86" );
   }


   override public function getOutputExtra() { return "android/PROJ"; }

   function addV4CompatLib(inDest:String)
   {
      var lib = project.environment.get("ANDROID_SDK") +
         "/extras/android/compatibility/v4/android-support-v4.jar";
      if (!FileSystem.exists(lib))
         lib = project.environment.get("ANDROID_SDK") +
            "/extras/android/support/v4/android-support-v4.jar";

      if (FileSystem.exists(lib))
         FileHelper.copyIfNewer(lib, inDest + "/libs/android-support-v4.jar");
      else
         Log.error("Could not find " + lib);
   }

   override public function updateOutputDir():Void 
   {
      super.updateOutputDir();

      var destination = getOutputDir();
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
      packageDirectory = destination + "/src/" + packageDirectory.split(".").join("/");
      PathHelper.mkdir(packageDirectory);
      copyTemplate("android/MainActivity.java", packageDirectory + "/MainActivity.java");

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

      for(javaPath in project.javaPaths) 
      {
         try 
         {
            if (FileSystem.isDirectory(javaPath)) 
               FileHelper.recursiveCopy(javaPath, destination + "/src", context, true);
            else
            {
               if (Path.extension(javaPath) == "jar") 
                  FileHelper.copyIfNewer(javaPath, destination + "/libs/" + Path.withoutDirectory(javaPath));
               else
                  FileHelper.copyIfNewer(javaPath, destination + "/src/" + Path.withoutDirectory(javaPath));
            }
         } catch(e:Dynamic) {}
      }
      addV4CompatLib(getOutputDir());

      for(k in project.dependencies.keys())
      {
         var lib = project.dependencies.get(k);
         if (lib.isAndroidProject())
            FileHelper.recursiveCopy( lib.getFilename(), getOutputDir()+"/"+getAndroidProject(lib), context, true);
      }
   }

}
