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
      context.ANDROIDVIEW = true;
   }

   override public function getOutputDir() { return targetDir + "/project"; }
   override public function getPlatformDir() : String { return "android-view"; }
   override public function getLibDir() { return getSdkDir() + "/libs/armeabi"; }

   function getSdkDir()     { return targetDir + "/" + project.app.file; }

   override public function copyBinary():Void
   {
      var sdk = getSdkDir();
      var buildDir = getOutputDir();

      var arm5 = sdk + "/libs/armeabi/libApplicationMain.so";
      FileHelper.copyIfNewer( buildDir + "/cpp/libApplicationMain" + (project.debug ? "-debug" : "") + ".so", arm5);
   }


   override public function postBuild():Void 
   {
      var sdk = getSdkDir();
      var buildDir = getOutputDir();

      var jarName = project.app.file + "_sdk.jar";
      FileHelper.copyIfNewer( buildDir + "/bin/classes.jar", sdk +"/libs/" + jarName);

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
