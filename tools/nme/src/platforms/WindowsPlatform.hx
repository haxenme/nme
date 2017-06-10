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
   }

   override public function runHaxe()
   {
	 
      var args = [haxeDir + "/build.hxml"];
      if (project.debug)
         args.push("-debug");

      if( project.winrtConfig.isWinrt )
      {
         args.push("-D");
         args.push("static_link");
         args.push("-D");
         args.push("ABI=-ZW");
      }

      runHaxeWithArgs(args);

      if( project.winrtConfig.isWinrt )
      {
          buildWinRTMain();
      }
   }

   public function buildWinRTMain()
   {
      var dest = haxeDir+"/cpp";
      var projectDirectory = getOutputDir();
      copyTemplateDir("winrt/static", dest );
      var args = [ "run", "hxcpp", "BuildMain.xml" ];
      if (project.debug)
         args.push("-debug");
      ProcessHelper.runCommand (dest, "haxelib", args);
   }

   override public function getPlatformDir() : String 
   { 
      if(project.winrtConfig.isWinrt)
      {
         return "winrt";
      }
      return useNeko ? "windows-neko" : "windows"; 
   }
   
   override public function getBinName() : String 
   { 
      if(project.winrtConfig.isWinrt)
      {
         return is64 ? "WinRT64" : "WinRT";
      }
      return is64 ? "Windows64" : "Windows";
   }

   override public function getNativeDllExt() { return ".dll"; }
   override public function getLibExt() { return ".lib"; }


   override public function copyBinary():Void 
   {
      if (useNeko) 
      {
         NekoHelper.createExecutable(haxeDir + "/ApplicationMain.n", executablePath);
      }
      else if(project.winrtConfig.isWinrt)
      {
         FileHelper.copyFile(haxeDir + "/cpp/Main" + (project.debug ? "-debug" : "") + ".exe", executablePath);
      }
      else
      {
         FileHelper.copyFile(haxeDir + "/cpp/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", executablePath);

         var ico = "icon.ico";
         var iconPath = PathHelper.combine(applicationDirectory, ico);

         if (IconHelper.createWindowsIcon(project.icons, iconPath)) 
         {
            outputFiles.push(ico);
            var replaceVI = CommandLineTools.nme + "/tools/nme/bin/ReplaceVistaIcon.exe";
            ProcessHelper.runCommand("", replaceVI , [ executablePath, iconPath ], true, true);
         }
      }
   }

   override public function run(arguments:Array<String>):Void 
   {
      var dir = deployDir!=null ? deployDir : applicationDirectory;

      if(project.winrtConfig.isWinrt)
      {
         var appxName = project.app.packageName;
         var appxId = "App";
         var appxAUMID:String = null; 
         var appxInfoFile = applicationDirectory + "/appxinfo.txt";
         var kitsRoot10 = "C:\\Program Files (x86)\\Windows Kits\\10\\"; //%WindowsSdkDir%

         Log.info("run: generate .pri file"); //see addManifest below
         var makepriParams = ["new", "/pr", applicationDirectory + "/temp", "/cf", applicationDirectory + "/temp/" + "priconfig.xml", "/mn", applicationDirectory + "/"+'AppxManifest.xml', "/of", applicationDirectory + "/"+"resources.pri", "/o"];
         var process = new sys.io.Process(kitsRoot10+'bin\\x86\\MakePri.exe', makepriParams);

         Log.info("run: Remove previous registered app");
         var process = new sys.io.Process('powershell', ["-noprofile", "-command",'Get-AppxPackage '+appxName+' | Remove-AppxPackage']);
         if (process.exitCode() != 0) {
            var message = process.stderr.readAll().toString();
            Log.error("Cannot remove. " + message);
         }
         process.close();

         Log.info("run: Register app");
         var process2 = new sys.io.Process('powershell', ["-noprofile", "-command",'Add-AppxPackage -Path '+applicationDirectory + "/"+'AppxManifest.xml -Register']);
         if (process2.exitCode() != 0) {
            var message = process2.stderr.readAll().toString();
            Log.error("Cannot register. " + message);
         }
         process2.close();

         //get PackageFamilyappxName and set appxAUMID
         //   write app info in a file
         var process3 = new sys.io.Process('powershell', ['Get-AppxPackage '+appxName+' | Out-File '+appxInfoFile+' -Encoding ASCII']);
         if (process3.exitCode() != 0) {
            var message = process3.stderr.readAll().toString();
            Log.error("Cannot get PackageFamilyName. " + message);
         }
         process3.close();
         //   parse file
         if(sys.FileSystem.exists(appxInfoFile))
         {
           var fin = sys.io.File.read(appxInfoFile, false);
           try
           {
              while(true)
              {
                 var str = fin.readLine();
                 var split = str.split (":");
                 var name = StringTools.trim(split[0]);
                 if( name == "PackageFamilyName")
                 {
                    var appxPackageFamilyName = StringTools.trim(split[1]);
                    if(appxPackageFamilyName!=null)
                    {
                        appxAUMID = appxPackageFamilyName+"!"+appxId;
                        break;
                    }
                 }
              }
           }
           catch(e:haxe.io.Eof)
           {
                Log.error('Could not get PackageFamilyName from '+appxInfoFile);
           }
           fin.close();
         }


         Log.info("run: "+appxAUMID);
         var process4 = new sys.io.Process(kitsRoot10+'App Certification Kit\\microsoft.windows.softwarelogo.appxlauncher.exe', [appxAUMID]);
         //if (process4.exitCode() != 0) {
         //   var message = process.stderr.readAll().toString();
         //   Log.error("Cannot run. " + message);
         // }

         return;
      }
      ProcessHelper.runCommand(dir, Path.withoutDirectory(executablePath), arguments);
   }


   override public function updateOutputDir():Void 
   {
      super.updateOutputDir();

      if(project.winrtConfig.isWinrt)
      {
         var destination = getOutputDir();
         copyTemplateDir( "winrt/appx", destination );
      }
   }

   override public function addManifest()
   {
      super.addManifest();

      if (project.winrtConfig.isWinrt)
      {
         //prepare file to make pri
         try
         {
            var from = getOutputDir();
            var buf = new StringBuf();
            for (filename in outputFiles)
            {
                if (!(StringTools.endsWith(filename,".exe") || 
                  StringTools.endsWith(filename,".pri") ||
                  StringTools.startsWith(filename,"temp/")
                  ) 
                  && filename!="AppxManifest.xml")
                {
                   buf.add(filename);
                   buf.addChar(10);
                }
            }
            var resultFileName = getOutputDir() + "/temp/layout.resfiles";
            if(sys.FileSystem.exists(resultFileName))
            {
               sys.FileSystem.deleteFile(sys.FileSystem.absolutePath(resultFileName));
            }
            sys.io.File.saveContent(resultFileName, buf.toString());
            Log.verbose("Created layout.resfiles : " + resultFileName);

        }
         catch(e:Dynamic)
         {
            Log.error("Error creating layout.resfiles " + e);
         }
      }
   }
}



