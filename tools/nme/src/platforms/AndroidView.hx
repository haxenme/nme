package platforms;

import platforms.AndroidPlatform.ABI;
import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class AndroidView extends AndroidPlatform
{
   var testDir:String;
   var hasRun:Bool;

   public function new(inProject:NMEProject)
   {
      super(inProject);
      testDir = "";
      hasRun = false;
      if (project.androidConfig.minApiLevel<11)
         project.androidConfig.minApiLevel = 11;
   }

   override private function generateContext(context:Dynamic)
   {
      super.generateContext(context);
      context.ANDROIDVIEW = true;
      context.CLASS_PACKAGE = project.androidConfig.viewPackageName;
      context.CLASS_NAME = project.app.file;
      context.GAME_ACTIVITY_BASE = project.androidConfig.gameActivityViewBase;
   }

   override public function getOutputDir() { return targetDir + "/project"; }
   override public function getPlatformDir() : String { return "android-view"; }
   override public function getLibDir() { return getSdkDir() + "/libs/armeabi"; }
   //override public function getOutputExtra() { return ""; }
   function getSdkDir()     { return targetDir + "/" + project.app.file; }

   override public function copyBinary():Void
   {
      var sdk = getSdkDir();

      var dbg = project.debug ? "-debug" : "";

      Lambda.iter(includedABIs(), function(abi:ABI) {
         var source = haxeDir + "/cpp/libApplicationMain" + dbg + '${abi.libArchSuffix}.so';
         var destination = sdk + '/libs/${abi.name}/libApplicationMain.so';
         FileHelper.copyIfNewer(source, destination);
      });
   }


   override public function postBuild():Void 
   {
      var sdk = getSdkDir();
      var buildDir = getOutputDir();

      PathHelper.mkdir(sdk+"/libs");
      var jarName = sdk + "/libs/" + project.app.file + "_sdk.jar";
      //FileHelper.copyIfNewer( buildDir + "/bin/classes.jar", sdk +"/libs/" + jarName);

      var jarExe = Sys.getEnv("JAVA_HOME");
      if (jarExe==null || jarExe=="")
         jarExe = "jar";
      else
         jarExe += "/bin/jar";

      ProcessHelper.runCommand("", jarExe, [ "cf", jarName, "-C", buildDir+"/bin/classes", "."]);


      // If there is an explicit "sdk" directory, use that
      if (!copyTemplateDir("android-view/sdk", sdk, false ))
      {
         // Otherwise, use the CLASS_APP template
         var pkg = project.androidConfig.viewPackageName;
         var pkgPath = pkg.split(".").join("/");
         var srcPath = sdk + "/src/" + pkgPath;
         PathHelper.mkdir(srcPath);
         copyTemplate("android-view/CLASS_APP.java", srcPath + "/" + project.app.file + ".java" );
      }
   }

   override public function prepareTest()
   {
      testDir = project.androidConfig.viewTestDir;
      if (testDir=="")
      {
         testDir = targetDir + "/AndroidViewTestApp";
         copyTemplateDir("android-view-test/AndroidViewTestApp", testDir);
         addV4CompatLib(testDir);
      }
      Log.verbose("Using test dir : " + testDir);
      FileHelper.recursiveCopy(getSdkDir(),testDir);
   }

   override public function trace():Void 
   {
      if (hasRun)
         super.trace();
   }

   override public function install():Void
   {
      if (testDir!="")
      {
         androidBuild( testDir );

         var build = "debug";
         if (project.certificate != null) 
            build = "release";
   
         if (project.androidConfig.viewTestDir=="")
         {
            var targetPath = FileSystem.fullPath(testDir) + "/bin/AndroidViewTestApp-" + build + ".apk";

            ProcessHelper.runCommand("", adbName, adbFlags.concat([ "install", "-r", targetPath ]) );
         }
      }
   }

   override public function run(arguments:Array<String>):Void
   {
      if (testDir!="" && project.androidConfig.viewTestDir=="")
      {
         var pkg = "com.nmehost.androidviewtestapp";
         var activityName = pkg + "/" + pkg + ".MainActivity";

         ProcessHelper.runCommand("", adbName, adbFlags.concat([ "shell", "am", "start", "-a", "android.intent.action.MAIN", "-n", activityName ]));
         hasRun = true;
      }
   }

   override public function updateOutputDir():Void 
   {
      super.updateOutputDir();

      var srcBuild =  getOutputDir() + "/src";

      // See if whole src dir is provided
      if (!copyTemplateDir("android-view/src", srcBuild, false) )
      {
         // Otherwise, use the CLASS_APP template
         var pkg = project.androidConfig.viewPackageName;
         var pkgPath = pkg.split(".").join("/");
         var srcPath = srcBuild + "/" + pkgPath;
         PathHelper.mkdir(srcPath);
         copyTemplate("android-view/CLASS_JAR.java", srcPath + "/" + project.app.file + "Base.java" );
      }
   }
}
