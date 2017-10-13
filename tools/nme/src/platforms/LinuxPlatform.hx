package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class LinuxPlatform extends DesktopPlatform
{
   private var applicationDirectory:String;
   private var executablePath:String;
   private var isRaspberryPi:Bool;

   public function new(inProject:NMEProject)
   {
      isRaspberryPi = false;
      if (inProject.targetFlags.exists("rpi")) 
         isRaspberryPi = true;

      if (isRaspberryPi)
      {
         is64 = true;
      }
      else if (PlatformHelper.hostPlatform == Platform.LINUX) 
      {
         var process = new Process("uname", [ "-a" ]);
         var output = process.stdout.readAll().toString();
         var error = process.stderr.readAll().toString();
         process.exitCode();
         process.close();

         if (output.toLowerCase().indexOf("raspberrypi") > -1) 
         {
            isRaspberryPi = true;
            is64 = true;
         }
         else if (inProject.hasDef("HXCPP_LINUX_ARMV7"))
         { 
             is64 = false;
             inProject.architectures = [ Architecture.ARMV7 ];
         }
         else if (inProject.hasDef("HXCPP_LINUX_ARM64"))
         { 
             inProject.architectures = [ Architecture.ARM64 ];
             is64 = true;
         }
      }

      super(inProject);

      if (is64) 
         project.haxedefs.set("HXCPP_M64", "1");


      applicationDirectory = getOutputDir();
      executablePath = applicationDirectory + "/" + project.app.file;
      addOutput(executablePath);


      if (isRaspberryPi) 
         project.haxedefs.set("rpi", "1");
   }

   override public function getPlatformDir() : String
   {
      return isRaspberryPi ? "rpi" :( (useNeko ? "linux-neko" : "linux") + (is64 ? "64" : "") );
   }
   override public function getBinName() : String { return isRaspberryPi ? "RPi" : (is64 ? "Linux64" : "Linux"); }

   override public function getNativeDllExt() { return ".dso"; }

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


   override public function run(arguments:Array<String>):Void 
   {
      var dir = deployDir!=null ? deployDir : applicationDirectory;
      ProcessHelper.runCommand(dir, "./" + Path.withoutDirectory(executablePath), arguments);
   }
}


