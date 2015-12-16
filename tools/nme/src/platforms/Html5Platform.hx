package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;


class Html5Platform extends Platform
{
   private var applicationDirectory:String;

   public function new(inProject:NMEProject)
   {
      inProject.openflCompat = false;
      super(inProject);

      applicationDirectory = getOutputDir();

      project.haxeflags.push('-js $haxeDir/ApplicationMain.js');
   }

   override public function getPlatformDir() : String { return "html5"; }
   override public function getBinName() : String { return null; }
   override public function getNativeDllExt() { return null; }
   override public function getLibExt() { return null; }
   override public function getHaxeTemplateDir() { return "haxe"; }
   override public function getAssetDir() { return getOutputDir()+"/assets"; }


   override public function copyBinary():Void 
   {
     FileHelper.copyFile('$haxeDir/ApplicationMain.js',
                        '$applicationDirectory/${project.app.file}.js', addOutput);
   }

   override public function getOutputExtra() return "html5";

   override public function updateOutputDir():Void 
   {
      super.updateOutputDir();

      var destination = getOutputDir();

      var icon = IconHelper.getSvgIcon(project.icons);
      if (icon!=null)
      {
         FileHelper.copyFile(icon, destination + "/icon.svg", addOutput);
      }
      else
         IconHelper.createIcon(project.icons, 128, 128, destination + "/icon.png", addOutput);
   }


   override public function run(arguments:Array<String>):Void 
   {
      var fullPath =  FileSystem.fullPath('$applicationDirectory/index.html');
      new nme.net.URLRequest("file://" + fullPath).launchBrowser();
   }
}



