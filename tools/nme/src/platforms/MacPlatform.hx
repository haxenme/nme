package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class MacPlatform extends DesktopPlatform
{
   private var applicationDirectory:String;
   private var contentDirectory:String;
   private var executableDirectory:String;
   private var executablePath:String;

   public function new(inProject:NMEProject)
   {
      super(inProject);

      applicationDirectory = getOutputDir();
      contentDirectory = getAssetDir();
      executableDirectory = getExeDir();
      executablePath = executableDirectory + "/" + project.app.file;
      addOutput(executablePath);
   }



   override public function getOutputExtra() { return "mac"; }
   override public function getNativeDllExt() { return ".dylib"; }
   override public function getOutputDir() { return targetDir + "/" + project.app.file + ".app"; }
   override public function getExeDir() { return getOutputDir() + "/Contents/MacOS"; }
   override public function getAssetDir() { return getOutputDir() + "/Contents/Resources"; }
   override public function getBinName() : String { return is64 ? "Mac64" : "Mac"; }



   override public function copyBinary():Void 
   {
      if (useNeko) 
      {
         NekoHelper.createExecutable(haxeDir + "/ApplicationMain.n", executablePath);
      }
      else
      {
         FileHelper.copyFile(haxeDir + "/cpp/ApplicationMain" + (project.debug ? "-debug" : ""), executablePath);
      }

      ProcessHelper.runCommand("", "chmod", [ "755", executablePath ]);
   }

   override public function getPlatformDir() : String
   {
      return (project.targetFlags.exists("neko") ? "mac-neko" : "mac") + (is64 ? "64" : "");
   }

   override public function run(arguments:Array<String>):Void 
   {
      var exe =  Path.withoutDirectory(executablePath);
      var dir = deployDir!=null ? deployDir : executableDirectory;
      if (wantLldb())
         ProcessHelper.runCommand(dir, "lldb", [exe].concat(arguments) );
      else
         ProcessHelper.runCommand(dir, "./" + exe, arguments);
   }

   override public function updateOutputDir():Void 
   {
      super.updateOutputDir();
      context.HAS_ICON = IconHelper.createMacIcon(project.icons, PathHelper.combine(contentDirectory,"icon.icns"));
   }

}
