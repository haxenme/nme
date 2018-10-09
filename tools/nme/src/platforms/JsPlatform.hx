package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;


class JsPlatform extends Platform
{
   private var applicationDirectory:String;

   public function new(inProject:NMEProject)
   {
      inProject.openflCompat = false;
      super(inProject);

      applicationDirectory = getOutputDir();

      project.haxeflags.push('-js $haxeDir/ApplicationMain.js');
   }

   override public function getPlatformDir() : String { return "js"; }
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

   override public function getOutputExtra() return "js";

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


      for(dependency in project.dependencies)
      {
         if (dependency.path!=null)
         {
            FileHelper.copyFile(dependency.getFilename(), destination + "/" + dependency.name, addOutput);
         }
      }
   }

   override private function generateContext(context:Dynamic)
   {
      var linkedLibraries = [];
      for(dependency in project.dependencies)
         linkedLibraries.push(dependency.name);

      context.linkedLibraries = linkedLibraries;
   }

   override public function run(arguments:Array<String>):Void 
   {
      var server = new nme.net.http.Server( new nme.net.http.FileServer([FileSystem.fullPath(applicationDirectory) ]).onRequest  );

      var port = 2323;
      server.listen(port);
      new nme.net.URLRequest('http://localhost:$port/index.html' ).launchBrowser();

      server.untilDeath();



      //var fullPath =  FileSystem.fullPath('$applicationDirectory/index.html');
      //new nme.net.URLRequest("file://" + fullPath).launchBrowser();
   }
}



