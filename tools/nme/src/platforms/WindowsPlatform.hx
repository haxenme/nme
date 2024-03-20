package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class WindowsPlatform extends DesktopPlatform
{
   private var applicationDirectory:String;
   private var executableFile:String;
   private var executablePath:String;

   public function new(inProject:NMEProject)
   {
      super(inProject);

      applicationDirectory = getOutputDir();
      executableFile = project.app.file + ".exe";
      executablePath = applicationDirectory + "/" + executableFile;
      outputFiles.push(executableFile);

      if (!project.environment.exists("SHOW_CONSOLE")) 
         project.haxedefs.set("no_console", "1");
      if (getPlatformDir() != "winrt")
      {
         project.haxedefs.set("resourceFile", "resource.rc");
         var dpiAware = project.getDef("dpiAware");
         if (dpiAware=="changed")
            project.haxedefs.set("manifestFile", "NmeManifest.xml");
      }
   }

   override public function getPlatformDir() : String { return useNeko ? "windows-neko" : "windows"; }
   override public function getBinName() : String { return isArm64 ? "WindowsArm64" : is64 ? "Windows64" : "Windows"; }
   override public function getNativeDllExt() { return ".dll"; }
   override public function getLibExt() { return ".lib"; }
   override public function getBinaryName() { return executableFile; }

   override public function updateBuildDir():Void 
   {
      super.updateBuildDir();
      if (getPlatformDir() != "winrt")
         copyTemplateDir( "windows", haxeDir + "/cpp", true, false );
   }



   override public function copyBinary():Void 
   {
      if (useNeko) 
      {
         NekoHelper.createExecutable(haxeDir + "/ApplicationMain.n", executablePath);
      }
      else
      {
         FileHelper.copyFile(haxeDir + "/cpp/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", executablePath);

         var ico = "icon.ico";
         var iconPath = PathHelper.combine(applicationDirectory, ico);

         if (IconHelper.createWindowsIcon(project.icons, iconPath)) 
         {
            //outputFiles.push(ico);
            var replaceVI = CommandLineTools.nme + "/tools/nme/bin/ReplaceVistaIcon.exe";
            ProcessHelper.runCommand("", replaceVI , [ executablePath, iconPath ], true, true);
         }
      }
   }

   override public function run(arguments:Array<String>):Void 
   {
      var dir = deployDir!=null ? deployDir : applicationDirectory;
      ProcessHelper.runCommand(dir, Path.withoutDirectory(executablePath), arguments);
   }
}



