package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class AndroidHelper 
{
   private static var adbName:String;
   private static var adbPath:String;



   private static function getADB(project:NMEProject):Void 
   {
      adbPath = project.environment.get("ANDROID_SDK") + "/tools/";
      adbName = "adb";

      if (PlatformHelper.hostPlatform == Platform.WINDOWS) 
      {
         adbName += ".exe";
      }

      if (!FileSystem.exists(adbPath + adbName)) 
      {
         adbPath = project.environment.get("ANDROID_SDK") + "/platform-tools/";
      }

      if (PlatformHelper.hostPlatform != Platform.WINDOWS) 
      {
         adbName = "./" + adbName;
      }
   }

   public static function initialize(project:NMEProject):Void 
   {
      getADB(project);

      if (project.environment.exists("JAVA_HOME")) 
      {
         Sys.putEnv("JAVA_HOME", project.environment.get("JAVA_HOME"));
      }
   }

   public static function install(targetPath:String):Void 
   {
      ProcessHelper.runCommand(adbPath, adbName, [ "install", "-r", targetPath ]);
   }

   public static function run(activityName:String):Void 
   {
      ProcessHelper.runCommand(adbPath, adbName, [ "shell", "am", "start", "-a", "android.intent.action.MAIN", "-n", activityName ]);
   }

   public static function trace(project:NMEProject, debug:Bool):Void 
   {
   }

   public static function uninstall(packageName:String):Void 
   {
      ProcessHelper.runCommand(adbPath, adbName, [ "uninstall", packageName ]);
   }
}







class AndroidPlatform extends Platform
{
   public function new(inProject:NMEProject)
   {
      super(inProject);


      if (!project.environment.exists("ANDROID_SETUP")) 
      {
         LogHelper.error("You need to run \"nme setup android\" before you can use the Android target (or set ANDROID_SETUP manually)");
      }

      AndroidHelper.initialize(project);
   }

   override public function build():Void 
   {
      var destination = project.app.path + "/android/bin";
      var hxml = project.app.path + "/android/haxe/" + (project.debug ? "debug" : "release") + ".hxml";

      var arm5 = project.app.path + "/android/bin/libs/armeabi/libApplicationMain.so";
      var arm7 = project.app.path + "/android/bin/libs/armeabi-v7a/libApplicationMain.so";

      if (ArrayHelper.containsValue(project.architectures, Architecture.ARMV6)) 
      {
         ProcessHelper.runCommand("", "haxe", [ hxml ] );
         FileHelper.copyIfNewer(project.app.path + "/android/obj/libApplicationMain" + (project.debug ? "-debug" : "") + ".so", arm5);
      }
      else
      {
         if (FileSystem.exists(arm5)) 
         {
            FileSystem.deleteFile(arm5);
         }
      }

      if (ArrayHelper.containsValue(project.architectures, Architecture.ARMV7)) 
      {
         ProcessHelper.runCommand("", "haxe", [ hxml, "-D", "HXCPP_ARMV7" ] );
         FileHelper.copyIfNewer(project.app.path + "/android/obj/libApplicationMain-7" + (project.debug ? "-debug" : "") + ".so", arm7);
      }
      else
      {
         if (FileSystem.exists(arm7)) 
         {
            FileSystem.deleteFile(arm7);
         }
      }

      runBuild(destination);
   }


   public function getApiLevel(inMinimum:Int) : Int
   { 
      var result = inMinimum;
      if (project.environment.exists("ANDROID_SDK"))
         try
         {
            var best = 999999;
            var dir = project.environment.get("ANDROID_SDK");
            for(file in FileSystem.readDirectory(dir+"/platforms"))
            {
               if (file.substr(0,8)=="android-")
               {
                  var val = Std.parseInt(file.substr(8));
                  if (val>=inMinimum && val<best)
                  {
                     result = val;
                     best = val;
                  }
               }
            }
         } catch(e:Dynamic){}

     return result;
   }


   public function runBuild(projectDirectory:String):Void 
   {
      if (project.environment.exists("ANDROID_SDK")) 
      {
         Sys.putEnv("ANDROID_SDK", project.environment.get("ANDROID_SDK"));
      }

      var ant = project.environment.get("ANT_HOME");

      if (ant == null || ant == "") 
      {
         ant = "ant";
      }
      else
      {
         ant += "/bin/ant";
      }

      var build = "debug";

      if (project.certificate != null) 
      {
         build = "release";
      }

      // Fix bug in Android build system, force compile
      var buildProperties = projectDirectory + "/bin/build.prop";

      if (FileSystem.exists(buildProperties)) 
      {
         FileSystem.deleteFile(buildProperties);
      }

      ProcessHelper.runCommand(projectDirectory, ant, [ build ]);
   }

   override public function clean():Void 
   {
      var targetPath = project.app.path + "/android";

      if (FileSystem.exists(targetPath)) 
      {
         PathHelper.removeDirectory(targetPath);
      }
   }

   override public function display():Void 
   {
      var hxml = PathHelper.findTemplate(project.templatePaths, "android/hxml/" + (project.debug ? "debug" : "release") + ".hxml");

      var context = project.templateContext;
      context.CPP_DIR = project.app.path + "/android/obj";

      var template = new Template(File.getContent(hxml));
      Sys.println(template.execute(context));
   }

   override public function install():Void 
   {
      var build = "debug";

      if (project.certificate != null) 
      {
         build = "release";
      }

      AndroidHelper.install(FileSystem.fullPath(project.app.path) + "/android/bin/bin/" + project.app.file + "-" + build + ".apk");
   }

   override public function run(arguments:Array<String>):Void 
   {
      AndroidHelper.run(project.app.packageName + "/" + project.app.packageName + ".MainActivity");
   }

   override public function trace():Void 
   {
      AndroidHelper.trace(project, project.debug);
   }

   override public function uninstall():Void 
   {
      AndroidHelper.uninstall(project.app.packageName);
   }

   override public function update():Void 
   {
      var destination = project.app.path + "/android/bin/";
      PathHelper.mkdir(destination);
      PathHelper.mkdir(destination + "/res/drawable-ldpi/");
      PathHelper.mkdir(destination + "/res/drawable-mdpi/");
      PathHelper.mkdir(destination + "/res/drawable-hdpi/");
      PathHelper.mkdir(destination + "/res/drawable-xhdpi/");

      for(asset in project.assets) 
      {
            var targetPath = "";

            switch(asset.type) 
            {
               case SOUND, MUSIC:

                  asset.resourceName = asset.id;
                  targetPath = destination + "/res/raw/" + asset.flatName + "." + Path.extension(asset.targetPath);

               default:

                  asset.resourceName = asset.flatName;
                  targetPath = destination + "/assets/" + asset.resourceName;
            }

            FileHelper.copyAssetIfNewer(asset, targetPath);
      }

      if (project.targetFlags.exists("xml")) 
      {
         project.haxeflags.push("-xml " + project.app.path + "/android/types.xml");
      }

      var context = project.templateContext;

      context.CPP_DIR = project.app.path + "/android/obj";
      context.ANDROID_INSTALL_LOCATION = project.config.android.installLocation;

      var android_platform = project.environment.get("ANDROID_SDK_PLATFORM");
      var apiLevel:Null<Int> = 0;
      if (android_platform!=null && android_platform.length>0)
      { 
         if (android_platform.substr(0,8)=="android-")
            android_platform = android_platform.substr(8);
         apiLevel = Std.parseInt(android_platform);
      }

      if (apiLevel<8 || apiLevel==null) apiLevel = 8;

      context.ANDROID_API_LEVEL = getApiLevel(apiLevel);

      var iconTypes = [ "ldpi", "mdpi", "hdpi", "xhdpi" ];
      var iconSizes = [ 36, 48, 72, 96 ];

      for(i in 0...iconTypes.length) 
      {
         if (IconHelper.createIcon(project.icons, iconSizes[i], iconSizes[i], destination + "/res/drawable-" + iconTypes[i] + "/icon.png")) 
         {
            context.HAS_ICON = true;
         }
      }

      IconHelper.createIcon(project.icons, 732, 412, destination + "/res/drawable-xhdpi/ouya_icon.png");

      var packageDirectory = project.app.packageName;
      packageDirectory = destination + "/src/" + packageDirectory.split(".").join("/");
      PathHelper.mkdir(packageDirectory);

      //SWFHelper.generateSWFClasses(project, project.app.path + "/android/haxe");
      for(ndll in project.ndlls) 
      {
         FileHelper.copyLibrary(ndll, "Android", "lib", ".so", destination + "/libs/armeabi", project.debug);
      }

      for(javaPath in project.javaPaths) 
      {
         try 
         {
            if (FileSystem.isDirectory(javaPath)) 
            {
               FileHelper.recursiveCopy(javaPath, destination + "/src", context, true);
            }
            else
            {
               if (Path.extension(javaPath) == "jar") 
               {
                  FileHelper.copyIfNewer(javaPath, destination + "/libs/" + Path.withoutDirectory(javaPath));
               }
               else
               {
                  FileHelper.copyIfNewer(javaPath, destination + "/src/" + Path.withoutDirectory(javaPath));
               }
            }

         } catch(e:Dynamic) {}

         //   throw"Could not find javaPath " + javaPath +" required by extension."; 
         //}
      }

      FileHelper.recursiveCopyTemplate(project.templatePaths, "android/template", destination, context);
      FileHelper.copyFileTemplate(project.templatePaths, "android/MainActivity.java", packageDirectory + "/MainActivity.java", context);
      FileHelper.recursiveCopyTemplate(project.templatePaths, "haxe", project.app.path + "/android/haxe", context);
      FileHelper.recursiveCopyTemplate(project.templatePaths, "android/hxml", project.app.path + "/android/haxe", context);
   }
}
