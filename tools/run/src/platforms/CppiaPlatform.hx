package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class CppiaPlatform extends Platform
{
   private var applicationDirectory:String;

   public function new(inProject:NMEProject)
   {
      super(inProject);

      applicationDirectory = getOutputDir();

      project.haxeflags.push('-cpp $haxeDir/ScriptMain.cppia');
   }

   override public function getPlatformDir() : String { return "cppia"; }
   override public function getBinName() : String { return null; }
   override public function getNativeDllExt() { return null; }
   override public function getLibExt() { return null; }
   override public function getHaxeTemplateDir() { return "script"; }


   override public function copyBinary():Void 
   {
     FileHelper.copyFile('$haxeDir/ScriptMain.cppia',
                        '$applicationDirectory/ScriptMain.cppia');
   }

   override public function run(arguments:Array<String>):Void 
   {
      var host = project.getDef("CPPIA_HOST");
      if (host==null)
      {
         Log.error("Please define CPPIA_HOST to run the application");
      }
      var fullPath =  FileSystem.fullPath('$applicationDirectory/ScriptMain.cppia');
      ProcessHelper.runCommand("", host, [fullPath].concat(arguments));
   }
}



