package;

import sys.FileSystem;
import platforms.Platform;

class AndroidHelper 
{
   private static var adbName:String;
   private static var adbPath:String;

   public static function build(project:NMEProject, projectDirectory:String):Void 
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

   public static function getApiLevel(project:NMEProject, inMinimum:Int) : Int
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
