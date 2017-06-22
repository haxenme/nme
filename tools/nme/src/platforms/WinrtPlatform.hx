package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class WinrtPlatform extends WindowsPlatform
{

   public function new(inProject:NMEProject)
   {
      super(inProject);
   }

   override public function runHaxe()
   {
      var args = [haxeDir + "/build.hxml"];
      if (project.debug)
         args.push("-debug");

      args.push("-D");
      args.push("static_link");
      args.push("-D");
      args.push("ABI=-ZW");

      runHaxeWithArgs(args);

      buildWinRTMain();
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

   override public function getPlatformDir() : String { return "winrt"; }
   override public function getBinName() : String { return is64 ? "WinRT64" : "WinRT"; }

   override public function copyBinary():Void 
   {
      FileHelper.copyFile(haxeDir + "/cpp/Main" + (project.debug ? "-debug" : "") + ".exe", executablePath);
   }

   override public function run(arguments:Array<String>):Void 
   {
      var dir = deployDir!=null ? deployDir : applicationDirectory;

      if(project.winrtConfig.isAppx)
      {
          Log.info("Double click on "+project.app.file + ".Appx to run");
      }
      else
      {
         var appxName = project.app.packageName;
         var appxId = "App";
         var appxAUMID:String = null; 
         var appxInfoFile = applicationDirectory + "/appxinfo.txt";
         var kitsRoot10 = "C:\\Program Files (x86)\\Windows Kits\\10\\"; //%WindowsSdkDir%

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
      }
   }


   override public function updateOutputDir():Void 
   {
      super.updateOutputDir();
      var destination = getOutputDir();
      copyTemplateDir( "winrt/appx", destination );

      PathHelper.mkdir(destination + "/assetspkg/");

      var iconNames = [ "Square44x44Logo.targetsize-24_altform-unplated", "LockScreenLogo.scale-200", "StoreLogo", "Square44x44Logo.scale-200", "Square150x150Logo.scale-200" ];
      var iconSizes = [ 24, 48, 50, 88, 300 ];

      for(i in 0...iconNames.length) 
      {
         if (IconHelper.createIcon(project.icons, iconSizes[i], iconSizes[i], destination + "/assetspkg/" + iconNames[i] + ".png")) 
            context.HAS_ICON = true;
      }

      IconHelper.createIcon(/*project.banners!=null ? project.banners :*/ project.icons, 1240, 600,
         destination + "/assetspkg/SplashScreen.scale-200.png");
      IconHelper.createIcon(/*project.banners!=null ? project.banners :*/ project.icons, 620, 300,
         destination + "/assetspkg/Wide310x150Logo.scale-200.png");
   }


   override public function install() { 
      super.install();
      if(!project.winrtConfig.isAppx)
      {
        uninstall();
        Log.info("run: Register app");
        var process = new sys.io.Process('powershell', ["-noprofile", "-command",'Add-AppxPackage -Path '+applicationDirectory + "/"+'AppxManifest.xml -Register']);
        if (process.exitCode() != 0) {
            var message = process.stderr.readAll().toString();
            Log.error("Cannot register. " + message);
        }
        process.close();
      }
   }

   override public function uninstall() { 
      super.uninstall();
      if(!project.winrtConfig.isAppx)
      {
        var appxName = project.app.packageName;
        Log.info("run: Remove previous registered app");
        var process = new sys.io.Process('powershell', ["-noprofile", "-command",'Get-AppxPackage '+appxName+' | Remove-AppxPackage']);
        if (process.exitCode() != 0) {
          var message = process.stderr.readAll().toString();
          Log.error("Cannot remove. " + message);
        }
        process.close();        
      }
   }


   override public function buildPackage():Void 
   {
      super.buildPackage();
      if(project.winrtConfig.isAppx)
      {
        var kitsRoot10 = "C:\\Program Files (x86)\\Windows Kits\\10\\"; //%WindowsSdkDir%
        Log.info("make pri");

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

        var makepriParams = ["new", "/pr", applicationDirectory + "/temp", "/cf", applicationDirectory + "/temp/" + "priconfig.xml", "/mn", applicationDirectory + "/"+'AppxManifest.xml', "/of", applicationDirectory + "/"+"resources.pri", "/o"];
        var process = new sys.io.Process(kitsRoot10+'bin\\x86\\MakePri.exe', makepriParams);

        Log.info("make appx");
        var makeappParams = ["pack", "/d", applicationDirectory, "/p", applicationDirectory+"/../"+project.app.file+".Appx" ];
        var process2 = new sys.io.Process(kitsRoot10+'bin\\x86\\MakeAppx.exe', makeappParams);
        Log.info(kitsRoot10+'bin\\x86\\MakeAppx.exe');
        Log.info(makeappParams.toString());
        process.close();
        process2.close();
        // "C:\Program Files (x86)\Windows Kits\10\bin\x86\MakeAppx.exe" pack /d HerokuShaders /p HerokuShaders
        //powershell 'Add-AppxPackage HerokuShaders.appx'
      }
    }

   override function generateContext(context:Dynamic) : Void
   {
      context.appCapability = project.winrtConfig.appCapability;
      context.ENV_DCS = "::";
      context.APP_ARCH = is64? "x64" : "x86";
   }
}



