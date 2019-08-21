package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class WinrtPlatform extends WindowsPlatform
{
   public function new(inProject:NMEProject)
   {
      pathsInit = false;
      super(inProject);
   }

   override public function getPlatformDir() : String { return "winrt"; }
   override public function getBinName() : String { return is64 ? "WinRT64" : "WinRT"; }

   override public function copyBinary():Void 
   {
      FileHelper.copyFile(haxeDir + "/cpp/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", executablePath);
   }

   override public function run(arguments:Array<String>):Void 
   {
      var dir = deployDir!=null ? deployDir : applicationDirectory;

      if(project.winrtConfig.isAppx)
      {
          Log.info("\n***Double click on "+project.app.file + ".Appx to install Appx");
      }
      else
      {
         initializePathVariables(); //Init kitsRoot10
         var appxName = project.app.packageName;
         var appxId = "App";
         var appxAUMID:String = null; 
         var appxInfoFile = haxeDir + "/cpp/appxinfo.txt";

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
      }
   }

   override public function updateOutputDir():Void 
   {
      super.updateOutputDir();
      var destination = getOutputDir();
      copyTemplateDir( "winrt/appx", haxeDir + "/cpp" );
      FileHelper.copyFile(haxeDir + "/cpp/AppxManifest.xml", destination+"/AppxManifest.xml");
      PathHelper.mkdir(destination + "/assetspkg/");
      var iconNames = [ "Square44x44Logo.targetsize-24_altform-unplated", "LockScreenLogo.scale-200", "StoreLogo", "Square44x44Logo.scale-200", "Square150x150Logo.scale-200" ];
      var iconSizes = [ 24, 48, 50, 88, 300 ];
      for(i in 0...iconNames.length) 
      {
         if (IconHelper.createIcon(project.icons, iconSizes[i], iconSizes[i], destination + "/assetspkg/" + iconNames[i] + ".png")) 
            context.HAS_ICON = true;
      }
      IconHelper.createIcon(project.icons, 1240, 600, destination + "/assetspkg/SplashScreen.scale-200.png");
      IconHelper.createIcon(project.icons, 620, 300,  destination + "/assetspkg/Wide310x150Logo.scale-200.png");
   }

   override public function install()
   { 
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

   override public function uninstall()
   { 
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
      initializePathVariables(); //Init windowsSdkVerBinPath

      if(project.winrtConfig.isAppx)
      {
         var resultFilePath = haxeDir +"/cpp/temp";
         var resultFileName = resultFilePath +"/layout.resfiles";

         Log.info("Make pri");

         //prepare file to make pri
         try
         {
            var from = getOutputDir();
            var buf = new StringBuf();
            for (filename in outputFiles)
            {
               if (!(StringTools.endsWith(filename,".exe") || 
                    StringTools.endsWith(filename,".pri") ) 
                    && filename!="AppxManifest.xml")
                {
                    buf.add(filename);
                    buf.addChar(10);
                }
            }
            if(sys.FileSystem.exists(resultFileName))
               sys.FileSystem.deleteFile(sys.FileSystem.absolutePath(resultFileName));

            sys.io.File.saveContent(resultFileName, buf.toString());
            Log.verbose("Created layout.resfiles : " + resultFileName);
         }
         catch(e:Dynamic)
         {
            Log.error("Error creating layout.resfiles " + e);
         }

         var makepriParams = ["new", "/pr", resultFilePath, "/cf", resultFilePath + "/priconfig.xml", "/mn", applicationDirectory + "/"+'AppxManifest.xml', "/of", applicationDirectory + "/"+"resources.pri", "/o"];
         var process = new sys.io.Process(windowsSdkVerBinPath+'bin\\x86\\MakePri.exe', makepriParams);

         //needs to wait make pri
         var retry:Int = 10;
         while (retry>0 && !sys.FileSystem.exists(applicationDirectory + "/"+"resources.pri"))
         {
            Sys.sleep(1);
            Log.info("waiting pri..");
            retry--;
         }
         if (retry<=0)
            Log.error("Error on MakePri");

         var appxDir = applicationDirectory+"/../";
         Log.info("make "+project.app.file+".Appx");
         var makeappParams = ["pack", "/d", applicationDirectory, "/p", appxDir+project.app.file+".Appx" ];
         var process2 = new sys.io.Process(windowsSdkVerBinPath+'bin\\x86\\MakeAppx.exe', makeappParams);
         Log.info(windowsSdkVerBinPath+'bin\\x86\\MakeAppx.exe');
         Log.info(makeappParams.toString());
         process.close();
         process2.close();

         var pfxPath:String = null;
         var certificatePwd:String = null;

         if (project.certificate != null && (project.certificate.path != null || project.certificate.path.length==0))
         {
            if (sys.FileSystem.exists(project.certificate.path))
            {
               //apply certificate
                Log.info("cert path: " +project.certificate.path+", pwd:"+project.certificate.password);
                pfxPath = project.certificate.path;
                certificatePwd = project.certificate.password;                    
            }
            else
            {
               pfxPath = project.certificate.path;
               certificatePwd = project.certificate.password;

               //create certificate
               Log.warn("Warn: certificate " +project.certificate.path+" not found, creting new one");
               Log.info("get certificate powershell scripts");
               copyTemplateDir( "winrt/scripts", applicationDirectory+"/.." );
               var pfxFileName =  project.app.file+".pfx";

               //New certificate, calls powershell script on elevated mode
               var cmd = "Start-Process powershell \"-ExecutionPolicy Bypass -Command `\"cd `\""+sys.FileSystem.absolutePath(applicationDirectory)+"/.."+"`\"; & `\".\\newcertificate.ps1`\"`\"\" -Verb RunAs";
               var process3 = new sys.io.Process("powershell.exe", ["-Command", cmd]);    
               if (process3.exitCode() != 0)
               {
                  var message = process3.stderr.readAll().toString();
                  Log.error("Error newcertificate. " + message);
               }
               process3.close();

               //check pfx
               retry = 10;
               while (retry>0 && !sys.FileSystem.exists(appxDir+pfxFileName))
               {
                  Log.info("waiting "+appxDir+pfxFileName);
                  Sys.sleep(1);
                  retry--;
               }
               if (retry<=0)
                  Log.error("Error creating certificate");

               if(appxDir+pfxFileName != pfxPath)
               {
                  FileHelper.copyFile(appxDir+pfxFileName, pfxPath);
                  if (!sys.FileSystem.exists(pfxPath))
                  {
                     Log.error("could not copy "+appxDir+pfxFileName+" to "+pfxPath);
                  }
               }
            }
         }
         if (pfxPath!=null && certificatePwd!=null && pfxPath.length>0 && certificatePwd.length>0)
         {
            Log.info("signing "+project.app.file+".Appx with " + pfxPath);
            var signParams = ["sign", "/fd", "SHA256", "/a", "/f", pfxPath, "/p", certificatePwd, appxDir+project.app.file+".Appx"];
            Log.info(windowsSdkVerBinPath+"bin\\x64\\SignTool.exe "+signParams);
            var process4 = new sys.io.Process(windowsSdkVerBinPath+"bin\\x64\\SignTool.exe", signParams);
            if (process4.exitCode() != 0)
            {
               var message = process4.stderr.readAll().toString();
               Log.error("Error signing appx. " + message);
            }
            Log.info("\n\n***Double click "+pfxPath+" to setup certificate (Local machine, Place all certificates in the following store->Trusted People)\n");
            process4.close();
         }
      }
   }

   override function generateContext(context:Dynamic) : Void
   {
      initializePathVariables(); //Init productVersion
      context.appCapability = project.winrtConfig.appCapability;
      context.packageDependency = project.winrtConfig.packageDependency;
      context.ENV_DCS = "::";
      context.APP_ARCH = is64? "x64" : "x86";
      context.APP_TARGET = project.winrtConfig.isXbox ? "Windows.Xbox" : "Windows.Universal";
      context.APP_MINVERSION = "10.0.14393.0"; //Minimum requirement for Xbox One UWP
      context.APP_MAXVERSION = productVersion;
      if(!project.environment.exists("APP_CERTIFICATE_PWD") && project.certificate!=null && project.certificate.password!=null)
      {
         project.environment.set("APP_CERTIFICATE_PWD",project.certificate.password);
      }
   }

   private var windowsSdkVerBinPath:String;
   private var kitsRoot10:String;
   private var productVersion:String;
   private var pathsInit:Bool;
   private function initializePathVariables() : Void
   {
      if(!pathsInit)
      {
         pathsInit = true;

         var bQueryRegistry = true; //set to false to force environment variables but requires run from VS Developer command prompt
         if(bQueryRegistry)
         {
            Log.verbose("Query registry");
            //REG QUERY "HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v10.0" 
            var process = new sys.io.Process('REG', ["QUERY", 'HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Microsoft SDKs\\Windows\\v10.0']);
            if (process.exitCode() != 0)
            {
               var message = process.stderr.readAll().toString();
               Log.warn("Cannot query register. " + message);
            }
            else
            {
               var message = process.stdout.readAll().toString();
               var lines:Array<String> = message.split("\n");
               for (line in lines)
               {
                  var keyValues:Array<String> = line.split("REG_SZ");
                  if(keyValues.length == 2)
                  {
                     var key = StringTools.trim(keyValues[0]);
                     if(key=="InstallationFolder")
                     {
                        kitsRoot10 = StringTools.trim(keyValues[1]);
                        Log.verbose("InstallationFolder:"+kitsRoot10);
                     }
                     else if(key=="ProductVersion")
                     {
                        productVersion = StringTools.trim(keyValues[1]);
                        productVersion += ".0";
                        Log.verbose("ProductVersion:"+productVersion);
                     }
                  }
               }
           }
           process.close();
        }

        if(kitsRoot10 != null && productVersion != null && kitsRoot10.length>0 && productVersion.length>0)
        {
           windowsSdkVerBinPath = kitsRoot10 + "bin\\" + productVersion +"\\";
           Log.verbose("WindowsSdkVerBinPath:"+windowsSdkVerBinPath);
           if (!sys.FileSystem.exists(windowsSdkVerBinPath)) 
           {
              windowsSdkVerBinPath = kitsRoot10 + "bin\\";
              if (sys.FileSystem.exists(windowsSdkVerBinPath)) 
                 Log.warn("Using old sdk binary");
              else
                 Log.error("Could not find the SDK bin directory");
           }
        }
        else
        {
            //Backup plan, if registry query fails for some reason
            if(Sys.getEnv("WindowsSdkDir")!=null && Sys.getEnv("WindowsSDKVersion")!=null)
            {
               kitsRoot10 = Sys.getEnv("WindowsSdkDir");
               var productVersionWithSlash:String = Sys.getEnv("WindowsSDKVersion");
               windowsSdkVerBinPath = kitsRoot10 + "bin\\" + productVersionWithSlash;
               productVersion = productVersionWithSlash.split("\\")[0];
            }
            else
            {
               Log.error("Could not find the SDK bin directory, try running from the Developer Command Prompt for VS");              
            }
         }
         Log.verbose("WindowsSdkVerBinPath: "+windowsSdkVerBinPath);
	 Log.verbose("KitsRoot10: "+kitsRoot10);
	 Log.verbose("ProductVersion: "+productVersion);
      }
   }

}
