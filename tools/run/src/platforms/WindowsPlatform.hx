package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class WindowsPlatform extends DesktopPlatform
{
   private var applicationDirectory:String;
   private var executablePath:String;

   public function new(inProject:NMEProject)
   {
      super(inProject);

      applicationDirectory = getOutputDir();
      executablePath = applicationDirectory + "/" + project.app.file + ".exe";

      if (!project.environment.exists("SHOW_CONSOLE")) 
         project.haxedefs.set("no_console", 1);
   }

   override public function getPlatformDir() : String { return useNeko ? "windows-neko" : "windows"; }
   override public function getBinName() : String { return is64 ? "Windows64" : "Windows"; }
   override public function getNativeDllExt() { return ".dll"; }


   override public function copyBinary():Void 
   {
      if (useNeko) 
      {
         NekoHelper.createExecutable(haxeDir + "/ApplicationMain.n", executablePath);
      }
      else
      {
         FileHelper.copyFile(haxeDir + "/cpp/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", executablePath);

         var iconPath = PathHelper.combine(applicationDirectory, "icon.ico");

         if (IconHelper.createWindowsIcon(project.icons, iconPath)) 
         {
            var replaceVI = CommandLineTools.nme + "/tools/command-line/bin/ReplaceVistaIcon.exe";
            ProcessHelper.runCommand("", replaceVI , [ executablePath, iconPath ], true, true);
         }
      }
   }

   override public function run(arguments:Array<String>):Void 
   {
      ProcessHelper.runCommand(applicationDirectory, Path.withoutDirectory(executablePath), arguments);
   }
}



