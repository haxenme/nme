package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class AndroidView extends AndroidPlatform
{
   public function new(inProject:NMEProject)
   {
      super(inProject);
      if (project.androidConfig.minApiLevel<11)
         project.androidConfig.minApiLevel = 11;
   }

   override private function generateContext(context:Dynamic)
   {
      super.generateContext(context);
      context.ANDROIDVIEW = true;
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

      if (buildV5)
         FileHelper.copyIfNewer(haxeDir + "/cpp/libApplicationMain" + dbg + ".so",
                sdk + "/libs/armeabi/libApplicationMain.so");

      if (buildV7)
         FileHelper.copyIfNewer(haxeDir + "/cpp/libApplicationMain" + dbg + "-v7.so",
                sdk + "/libs/armeabi-v7a/libApplicationMain.so" );

      if (buildX86)
         FileHelper.copyIfNewer(haxeDir + "/cpp/libApplicationMain" + dbg + "-x86.so",
                sdk + "/libs/x86/libApplicationMain.so" );
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

      ProcessHelper.runCommand("", jarExe, [ "cvf", jarName, "-C", buildDir+"/bin/classes", "."]);

      copyTemplateDir("android-view/sdk", sdk );
   }

   override public function install():Void { }

   override public function run(arguments:Array<String>):Void { }

   override public function updateOutputDir():Void 
   {
      super.updateOutputDir();

      var srcBuild =  getOutputDir() + "/src";

      copyTemplateDir("android-view/src", srcBuild);
   }
}
