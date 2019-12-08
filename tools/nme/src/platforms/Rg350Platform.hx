package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class Rg350Platform extends DesktopPlatform
{
   private var applicationDirectory:String;
   private var executablePath:String;

   public function new(inProject:NMEProject)
   {
      super(inProject);

      project.haxedefs.set("gcw0", "1");

      applicationDirectory = getOutputDir();
      executablePath = applicationDirectory + "/" + project.app.file;
      addOutput(executablePath);
   }

   override public function getPlatformDir() : String
   {
      return "rg350";
   }
   override public function getBinName() : String { return "GCW0"; }

   override public function getNativeDllExt() { return ".so"; }

   override public function copyBinary():Void 
   {
      FileHelper.copyFile(haxeDir + "/cpp/ApplicationMain" + (project.debug ? "-debug" : ""), executablePath);
      ProcessHelper.runCommand("", "chmod", [ "755", executablePath ]);
   }


   override public function run(arguments:Array<String>):Void 
   {
      trace('Deploy $deployDir');
   }
}



