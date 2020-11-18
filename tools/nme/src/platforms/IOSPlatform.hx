package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;
import NMEProject;

import haxe.io.Path;
import sys.io.Process;
import sys.FileSystem;



class IOSPlatform extends Platform
{
   private static var initialized = false;

   var buildV6:Bool;
   var buildV7:Bool;
   var buildArm64:Bool;
   var buildI386:Bool;
   var buildX86_64:Bool;

   var simulatorUid:String;
   var launchPid:Int;
   var redirectTrace:Bool;
   var linkedLibraries:Array<String>;

   var no3xResoltion:Bool;
  

   public function new(inProject:NMEProject)
   {
      super(inProject);

      launchPid = 0;
      redirectTrace = false;

      for(asset in project.assets) 
         asset.resourceName = asset.targetPath = asset.flatName;

      project.haxeflags.push('-cpp $haxeDir/cpp');
      project.haxeflags.push("-D HXCPP_CPP11");

      var architectures = project.architectures;
      var config = project.iosConfig;
      var deployment = Std.parseFloat(config.deployment);
      if ( deployment<9 && project.watchProject!=null)
      {
         deployment = 9;
         config.deployment="9.0";
      }
      if (config.sourceFlavour=="mm")
         project.haxeflags.push("-D objc");

      // If we support iphones with deployment < 5, we must support armv6 ...
      if ( (config.deviceConfig & IOSConfig.IPHONE) > 0 && deployment<5)
          ArrayHelper.addUnique(architectures, Architecture.ARMV6);
      else
      {
          ArrayHelper.addUnique(architectures, Architecture.ARMV7);
          ArrayHelper.addUnique(architectures, Architecture.ARM64);
      }

      ArrayHelper.addUnique(architectures, Architecture.X86_64);
   
      buildV6 = buildV7 = buildI386 = buildArm64 = buildX86_64 = false;

      if (project.command == "xcode")
      {
         for(arch in project.localDefines.get("xcodearch").split(" "))
         {
            Log.verbose("Target flags: " + arch );
            switch(arch)
            {
               case "i386":
                   buildI386 = true;
               case "x86_64":
                   buildX86_64 = true;
               case "armv6":
                   if (!hasArch(Architecture.ARMV6))
                      Log.error("Armv6 not supported");
                   buildV6 = true;
               case "armv7":
                   if (!hasArch(Architecture.ARMV7))
                      Log.error("Armv7 not supported");
                   buildV7 = true;
               case "arm64":
                   if (!hasArch(Architecture.ARM64))
                      Log.error("Arm64 not supported");
                   buildArm64 = true;
               default:
                   trace("Locals :" + project.localDefines);
                   trace("Env :" + project.environment);
                   trace("Sys :" + Sys.environment());
                   Log.error("Unknown arch " + arch);
             }
         }
      }
      else
      {
         var build = project.targetFlags;
         Log.verbose("Target flags: " + build);

         if (build.exists("simulator") ) // || build.exists("ios") ) 
         {
            redirectTrace = true;
            if (crankUpSimulatorIs64())
            {
               ArrayHelper.addUnique(architectures, Architecture.ARM64);
               buildX86_64 = true;
            }
            else
            {
               ArrayHelper.addUnique(architectures, Architecture.I386);
               buildI386 = true;
            }
         }

         if (build.exists("iphoneos") || build.exists("ios")) 
         {
            buildV6 = hasArch(Architecture.ARMV6);
            buildV7 = hasArch(Architecture.ARMV7);
            buildArm64 = hasArch(Architecture.ARM64);
         }
      }
      Log.verbose("Valid Archs: " + architectures );
   }

   override public function buildPackage():Void 
   {
      // Prevent re-entry
      Sys.putEnv("NME_ALREADY_BUILDING","BUILDING");

      xcodeBuild(project, targetDir);

      if (buildV6 || buildV7 || buildArm64)
      {
          var entitlements = targetDir + "/" + project.app.file + "/" + project.app.file + "-Entitlements.plist";

          sign(project, targetDir + "/bin", entitlements);
      }
   }

   override public function getBinName() : String { return "iPhone"; }
   override public function getAssetDir() { return getOutputDir() + "/assets"; }
   override public function getPlatformDir() : String { return "ios"; }


   override private function generateContext(context:Dynamic)
   {
      var config = project.iosConfig;

      context.HAS_ICON = false;
      context.HAS_LAUNCH_IMAGE = false;
      context.OBJC_ARC = false;
      context.PROJECT_DIRECTORY = Sys.getCwd();
      context.APP_FILE = project.app.file;
      context.REDIRECT_TRACE = redirectTrace;
      context.IOS_3X_RESOLUTION = project.getBool("ios3xResolution",true);
      context.WATCHOS_DEPLOYMENT_TARGET = "2.2";
      context.HXCPP_GEN_DIR = haxeDir + "/cpp";
      var hxcpp = PathHelper.getHaxelib(new Haxelib("hxcpp"),true);
      var hxcpp_include = hxcpp==null ? "" : " " + hxcpp + "/include";
      context.HXCPP_INCLUDE_DIR = hxcpp_include;
      context.NME_IOS_INCLUDE = 'haxe/cpp/include';
      if (project.hasDef("nme_metal"))
         context.NME_METAL = true;

      if (project.watchProject!=null)
      {
         context.NME_WATCHOS = true;
         context.NME_WATCHOS_INCLUDE = '../watchos/haxe/cpp/include
${hxcpp_include}';

         if (project.watchProject.window.ui=="spritekit")
         {
            context.NME_WATCH_SPRITEKIT = true;
            context.WATCHOS_DEPLOYMENT_TARGET = "3.0";
         }

         var col = project.watchProject.window.background;
         context.TINT_RED = ((col>>16) & 0xff) / 0xff;
         context.TINT_GREEN = ((col>>8) & 0xff) / 0xff;
         context.TINT_BLUE = ((col) & 0xff) / 0xff;
         context.TINT_ALPHA = 1;
      }

      var devTeam = project.getDef("DEVELOPMENT_TEAM");
      if (devTeam!=null)
          context.DEVELOPMENT_TEAM = devTeam;


      linkedLibraries = [];
      for(dependency in project.dependencies)
         if (dependency.isLibrary())
         {
            var filename = dependency.getFilename();
            linkedLibraries.push(filename);
         }

      context.linkedLibraries = linkedLibraries;

      var valid_archs = new Array<String>();
      var current_archs = new Array<String>();


      for(architecture in project.architectures)
      {
         switch(architecture)
         {
            case ARMV6: valid_archs.push("armv6"); current_archs.push("armv6");
            case ARMV7: valid_archs.push("armv7"); current_archs.push("armv7");
            case ARM64: valid_archs.push("arm64"); current_archs.push("arm64");
            case X86_64: valid_archs.push("x86_64"); current_archs.push("x86_64");
            case I386: valid_archs.push("i386");
            default:
         }
      }

      context.CURRENT_ARCHS = "( " + current_archs.join(",") + ") ";

      context.VALID_ARCHS = valid_archs.join(" ");
      context.THUMB_SUPPORT = hasArch(ARMV6) ? "GCC_THUMB_SUPPORT = NO;" : "";
      context.KEY_STORE_IDENTITY = "iPhone Developer";


      var customIOSproperties = [];
      for(key in project.customIOSproperties.keys()) {
          var value = project.customIOSproperties.get(key);
          customIOSproperties.push( { key: key, value: value} );
      }
      context.CUSTOM_IOS_PROPERTIES = customIOSproperties;

      context.stageViewHead = project.iosConfig.stageViewHead;
      context.stageViewInit = project.iosConfig.stageViewInit;

      var blocks = [];
      for (i in 0...project.customIOSBlock.length) {
          var value = project.customIOSBlock[i];
          blocks.push({value:value});
      }
      context.CUSTOM_BLOCKS = blocks;
       
      context.BUILD_TOOL_PATH = getAbsolutePath("haxelib");

      var requiredCapabilities = [];

      if (hasArch(ARMV7) && !hasArch(ARMV6))
         requiredCapabilities.push( { name: "armv7", value: true } );

      context.REQUIRED_CAPABILITY = requiredCapabilities;
      context.ARMV6 = hasArch(ARMV6);
      context.ARMV7 = hasArch(ARMV7);
      context.ARM64 = hasArch(ARM64);
      context.TARGET_DEVICES = switch(config.deviceConfig)
      {
        case IOSConfig.IPHONE : "1";
        case IOSConfig.IPAD : "2";
        case _ : "1,2";
      }
      context.DEPLOYMENT = config.deployment;

      if (config.compiler == "llvm" || config.compiler == "clang")
      {
         context.OBJC_ARC = true;
      }

      context.IOS_COMPILER = config.compiler;
      context.IOS_LINKER_FLAGS = config.linkerFlags.join(", ");

      context.otherLinkerFlags = project.otherLinkerFlags;
      context.frameworkSearchPaths = project.frameworkSearchPaths;

      context.MACROS = {};
      context.MACROS.launchImage = createLaunchImage;
      context.MACROS.appIcon = createAppIcon;

      switch(project.window.orientation)
      {
         case PORTRAIT:
            context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
         case LANDSCAPE:
            context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string></array>";
         case ALL:
            context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
         //case "allButUpsideDown":
            //context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string></array>";
         default:
            context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
      }

      context.ADDL_PBX_BUILD_FILE = "";
      context.ADDL_PBX_FILE_REFERENCE = "";
      context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE = "";
      context.ADDL_PBX_FRAMEWORK_GROUP = "";
      var imports = new Array<String>();

      for(dependency in project.dependencies)
        if (dependency.isFramework())
        {
           var lib = dependency.getFramework();
           if(dependency.path == '' && false)
           {
              imports.push( "@import " + lib.split(".framework")[0] + ";" );
           }
           else
           {
              var frameworkID = "11C0000000000018" + StringHelper.getUniqueID();
              var fileID = "11C0000000000018" + StringHelper.getUniqueID();
              var path:String = 'System/Library/Frameworks';
              if(dependency.path != '')
              {
                  path = dependency.path;
                  if (path=="PROJ")
                     path = project.app.file;
                  else
                     project.frameworkSearchPaths.push(path);
              }
              var sourceTree:String = "SDKROOT";
               if(dependency.sourceTree != '') {
                   sourceTree = dependency.sourceTree;
                   if(sourceTree == 'group') {
                       sourceTree = "\"<group>\"";
                   }
               }
              context.ADDL_PBX_BUILD_FILE += '      $frameworkID /* $lib in Frameworks */ = {isa = PBXBuildFile; fileRef = $fileID /* $lib */; };\n';
              context.ADDL_PBX_FILE_REFERENCE += '     $fileID /* $lib */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = $lib; path = "$path/$lib"; sourceTree = $sourceTree; };\n';
              context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE += '            $frameworkID /* $lib in Frameworks */,\n';
              context.ADDL_PBX_FRAMEWORK_GROUP += '            $fileID /* $lib */,\n';
           }
        }

      context.PRERENDERED_ICON = config.prerenderedIcon;
      context.FRAMEWORK_IMPORTS = imports.join("\n");
      //updateIcon();
      //updateLaunchImage();
   }

   private function getAbsolutePath(binary:String): String {
       var process:Process = new Process("which", [binary]);
       if(process.exitCode(true) != 0) {
          var stderror = process.stderr.readAll().toString();
          throw "getAbsolutePath error:\n${stderror}";
       }
       
       var stdout = process.stdout.readAll().toString();
       var lines = stdout.split("\n");
       return lines[0];
   }

   override public function trace()
   {
      if (wantLldb() && launchPid>0)
      {
         Sys.println("lldb use - 'continue'/'c' to finish launching");
         Sys.println("         - 'process interrupt' to force break");
         Sys.println("         - 'bt' for back trace/callstack");
         Sys.println("         - 'kill' to kill process");
         Sys.println("         - 'quit' to quit");
         Sys.command("lldb", [ "-p", launchPid+"" ] );
      }
      else if (simulatorUid!=null && simulatorUid!="")
      {
         Sys.command("tail", [ "-f", "~/Library/Logs/CoreSimulator/" + simulatorUid + "/system.log"] );
      }
   }


   override public function runHaxe()
   {
      var args = project.debug ? ['$haxeDir/build.hxml',"-debug"] : ['$haxeDir/build.hxml'];

      if (buildV6)
         runHaxeWithArgs(args.concat(["-D", "HXCPP_ARMV6", "-D", "iphoneos"]));

      if (buildV7)
         runHaxeWithArgs(args.concat(["-D", "HXCPP_ARMV7", "-D", "iphoneos"]));

      if (buildArm64)
         runHaxeWithArgs(args.concat(["-D", "HXCPP_ARM64", "-D", "iphoneos" ]));

      if (buildI386)
         runHaxeWithArgs(args.concat(["-D", "iphonesim"]));

      if (buildX86_64)
         runHaxeWithArgs(args.concat(["-D", "iphonesim", "-D", "HXCPP_M64"]));
   }

   function copyApplicationMain(end:String, arch:String)
   {
      var projectDirectory = getOutputDir();
      var file = haxeDir + "/cpp/libApplicationMain" + end;
      if (!FileSystem.exists(file))
         file =  haxeDir + "/cpp/ApplicationMain" + end;

      FileHelper.copyIfNewer(file, projectDirectory + "/lib/" + arch + "/libApplicationMain.a" );
   }


   override public function copyBinary():Void 
   {
      var dbg = project.debug ? "-debug" : "";

      if (buildV6)
         copyApplicationMain(dbg + ".iphoneos.a", "armv6" + dbg);

      if (buildV7)
         copyApplicationMain(dbg + ".iphoneos-v7.a", "armv7" + dbg);

      if (buildArm64)
         copyApplicationMain(dbg + ".iphoneos-64.a", "arm64" + dbg);

      if (buildI386)
         copyApplicationMain(dbg + ".iphonesim.a", "i386" + dbg);

      if (buildX86_64)
         copyApplicationMain(dbg + ".iphonesim-64.a", "x86_64" + dbg);
   }

   override public function run(arguments:Array<String>):Void 
   {
      launch(project, targetDir);
   }

   function createLaunchImage( resolve : String -> Dynamic, widthStr:String, heightStr:String)
   {
      var width = Std.parseInt(widthStr);
      var height = Std.parseInt(heightStr);
      Log.verbose("createLaunchImage " + width + "x" + height);

      var name = "LaunchImage" + width + "x" + height + ".png";
      var dest = getOutputDir() + "/Images.xcassets/LaunchImage.launchimage/" + name;

      var ok = true;

      // check to see if any launch images are defined in the project that match this size
      for (splashScreen in project.splashScreens) {
        if (splashScreen.width == width && splashScreen.height == height) {
          try 
          {
            FileHelper.copyFile(splashScreen.path, dest);
          }
          catch(e:Dynamic)
          {
             Log.error("Could not copy launch image " + splashScreen.path + " to " + dest + " : " + e);
          }
          break;
        }
      }
      // if no splash exists (either preexisting or copied over) then we generate a blank image
      if (!FileSystem.exists(dest)) 
      {
        try
        {
          var bitmapData = new nme.display.BitmapData(width, height,
               false, (0xFF << 24) | (project.window.background & 0xFFFFFF));
          File.saveBytes(dest, bitmapData.encode("png"));
        }
        catch(e:Dynamic) 
        {
          ok = false;
          Log.error("Could create empty launch image " + dest + " : " + e);
        }
      }
      

      if (ok)
         return ", \"filename\":\"" + name + "\"";
      else
         return "";


   }

   function createAppIcon( resolve : String -> Dynamic, sizeStr:String ) : String
   {
      var size = Std.parseInt(sizeStr);
      Log.verbose("createAppIcon " + size + "x" + size);

      var name = "AppIcon" + size + "x" + size + ".png";
      var dest = getOutputDir() + "/Images.xcassets/AppIcon.appiconset/" + name;

      var ok = true;
      if (!FileSystem.exists(dest))
         ok = IconHelper.createIcon(project.icons, size,size, dest);
      if (ok)
         return ", \"filename\":\"" + name + "\"";
      else
         return "";
   }

      override public function updateBuildDir():Void 
   {
      super.updateBuildDir();
      PathHelper.mkdir(haxeDir+"/cpp/src");
      copyTemplate("ios/UIStageView.mm", haxeDir+"/cpp/src/UIStageView.mm");
   }



   override public function updateOutputDir():Void 
   {
      var nmeLib = new Haxelib("nme");

      var projectDirectory = getOutputDir();

      PathHelper.mkdir(targetDir);
      PathHelper.mkdir(projectDirectory);


      // Do not update if we are running from inside xcode
      if (project.command!="xcode")
      {
         copyTemplate("ios/PROJ/PROJ-Entitlements.plist", projectDirectory + "/" + project.app.file + "-Entitlements.plist");
         copyTemplate("ios/PROJ/PROJ-Info.plist", projectDirectory + "/" + project.app.file + "-Info.plist");
         copyTemplate("ios/PROJ/PROJ-Prefix.pch", projectDirectory + "/" + project.app.file + "-Prefix.pch");
         copyTemplateDir("ios/PROJ.xcodeproj", targetDir + "/" + project.app.file + ".xcodeproj");

         // Copy all the rest, except the "PROJ" files...
         copyTemplateDir("ios/PROJ", projectDirectory, true, true, name -> name.substr(0,4)!="PROJ" );
         //copyTemplateDir("ios/PROJ/Classes", projectDirectory + "/Classes");
         //copyTemplateDir("ios/PROJ/Images.xcassets", projectDirectory + "/Images.xcassets");


         var watchos = project.watchProject;
         if (watchos!=null)
         {
             copyTemplateDir("ios/WATCHPROJ", targetDir + "/" + watchos.app.file);
             copyTemplateDir("ios/WATCHPROJ Extension", targetDir + "/" + watchos.app.file + " Extension");
             PathHelper.mkdir(targetDir + "/" + project.app.file + ".xcodeproj/xcshareddata/xcschemes"  );
             copyTemplate("ios/schemes/Watch.xcscheme", targetDir + "/" + project.app.file + ".xcodeproj/xcshareddata/xcschemes/Watch.xcscheme"  );
         }
      }

      if (project.command == "update" && PlatformHelper.hostPlatform == Platform.MAC) 
         ProcessHelper.runCommand("", "open", [ targetDir + "/" + project.app.file + ".xcodeproj" ] );
   }

   override public function updateLibs()
   {
      var projectDirectory = getOutputDir();

      PathHelper.mkdir(projectDirectory + "/lib");

      for(archID in 0...5) 
      {
         var arch = [ "armv6", "armv7", "i386", "arm64", "x86_64" ][archID];

         if (arch == "armv6" && !context.ARMV6)
            continue;

         if (arch == "armv7" && !context.ARMV7)
            continue;

         if (arch == "arm64" && !context.ARM64)
            continue;

         var libExt = [ ".iphoneos.a", ".iphoneos-v7.a", ".iphonesim.a", ".iphoneos-64.a", ".iphonesim-64.a"  ][archID];

         PathHelper.mkdir(projectDirectory + "/lib/" + arch);
         PathHelper.mkdir(projectDirectory + "/lib/" + arch + "-debug");

         for(ndll in project.ndlls) 
         {
            {
               var releaseLib = ndll.find("iPhone", "lib", libExt);
               var releaseDest = projectDirectory + "/lib/" + arch + "/lib" + ndll.name + ".a";

               //trace(releaseLib);
               //trace(releaseDest);
               if (!FileSystem.exists(releaseLib))
                  Log.verbose("Skip non-existent library " + releaseLib );
               else
                  FileHelper.copyIfNewer(releaseLib, releaseDest);
            }
         }
      }
   }





   public function xcodeBuild(project:NMEProject, workingDirectory:String, additionalArguments:Array<String> = null):Void 
   {
      initialize(project);

      var platformName = "iphoneos";

        var configuration = "Release";
        if (project.debug) 
            configuration = "Debug";

        var sim64 = true;
        if (project.targetFlags.exists("simulator")) 
            platformName = "iphonesimulator";

        var iphoneVersion = project.environment.get("IPHONE_VER");
        var commands = [ "-configuration", configuration, "-allowProvisioningUpdates", "PLATFORM_NAME=" + platformName, "SDKROOT=" + platformName + iphoneVersion ];

        if (project.targetFlags.exists("simulator")) 
        {
            commands.push("-arch");
            commands.push(buildX86_64 ? "x86_64" : "i386" );
        }

        if (additionalArguments != null) 
           commands = commands.concat(additionalArguments);

        ProcessHelper.runCommand(workingDirectory, "xcodebuild", commands);
        //ProcessHelper.runCommand(workingDirectory + "/" + project , "xcodebuild", commands);
   }

   function waitBooted()
   {
      for(attempt in 0...30)
      {
         var sims = ProcessHelper.getOutput("xcrun", ["simctl", "list", "devices"]);
         var seenUid = false;
         for(sim in sims)
         {
            if (sim.indexOf("Booted")>=0)
            {
               Log.verbose("Found booted device " + sim);
               return;
            }
            if (sim.indexOf(simulatorUid)>=0)
              seenUid = true;
         }
         if (!seenUid)
            Log.error("Target simulator " + simulatorUid + " is missing from " + sims.join(","));

         Sys.println("Waiting for simulator to boot ...");
         Sys.sleep(1);
      }
      Log.error("Time out waiting for simultor to boot");
   }

   // Returns whether 64 bit is wanted
   public function crankUpSimulatorIs64() : Bool
   {
      var sims = ProcessHelper.getOutput("xcrun", ["simctl", "list", "devices"]);
      var foundSim = "";
      var foundUid = "";
      var isBooted = false;
      var allSims = new Array<String>();
      var allUids = new Array<String>();

      for(sim in sims)
      {
         var extractSim = ~/^\s*(.*) \((.*)\) \((.*)\)/;
         if (extractSim.match(sim))
         {
            var name = extractSim.matched(1);
            var uid = extractSim.matched(2);
            var status = extractSim.matched(3);
            Log.verbose(' Found simulator "$name" status="$status"');
            allSims.push(name);
            allUids.push(uid);
            if (status=="Booted")
            {
               Log.verbose("Found booted simulator " + name);
               foundSim = name;
               isBooted = true;
               foundUid = uid;
            }
         }
      }

      if (allSims.length==0)
         Log.error("Could not find simulator list from 'xcrun simctl list devices'");

      if (foundSim=="")
      {
         var sought = project.getDef("iosdevice");
         if (sought==null || sought=="")
         {
            sought = "iPhone";
            Log.verbose("Seeking default device 'iPhone' - specify device with iosdevice='...' from :" + allSims.join(","));
         }

         var l = sought.length;
         for(sid in 0...allSims.length)
         {
            var s = allSims[sid];
            // Find the one most down the list...
            if (s.substr(0,l).toLowerCase() == sought.toLowerCase() || sought==allUids[sid])
            {
               foundSim = s;
               foundUid = allUids[sid];
            }
         }

         if (foundSim=="")
         {
            foundSim = allSims[ allSims.length-1 ];
            foundUid = allUids[ allUids.length-1 ];
         }
      }

      simulatorUid = foundUid;
      Log.verbose("Using simulator : " + foundSim + "/" + simulatorUid);

      if (!isBooted)
      {
         Log.verbose("Start simulator...");
         Sys.command("open", [ "-a", "iOS Simulator", "--args", "-CurrentDeviceUDID", foundUid]);
      }

      switch(foundSim)
      {
         case "iPhone 4s", "iPhone 5", "iPhone 5s", "iPad 2", "iPad Air":
            Log.verbose("Using 32bit simulator");
            return false;
         default:
            Log.verbose("Using default 64bit simulator");
            return true;
      }
   }

   public function getSDKDirectory(project:NMEProject):String 
   {
      initialize(project);

      var platformName = "iPhoneOS";

      if (project.targetFlags.exists("simulator")) 
      {
         platformName = "iPhoneSimulator";
      }

      var process = new Process("xcode-select", [ "--print-path" ]);
      var directory = process.stdout.readLine();
      process.close();

      if (directory == "" || directory.indexOf("Run xcode-select") > -1) 
      {
         directory = "/Applications/Xcode.app/Contents/Developer";
      }

      directory += "/Platforms/" + platformName + ".platform/Developer/SDKs/" + platformName + project.environment.get("IPHONE_VER") + ".sdk";
      return directory;
   }

   private function getIOSVersion(project:NMEProject):Void 
   {
      if (!project.environment.exists("IPHONE_VER")) 
      {
         if (!project.environment.exists("DEVELOPER_DIR")) 
         {
              var proc = new Process("xcode-select", ["--print-path"]);
              var developer_dir = proc.stdout.readLine();
              proc.close();
              project.environment.set("DEVELOPER_DIR", developer_dir);
          }
         var dev_path = project.environment.get("DEVELOPER_DIR") + "/Platforms/iPhoneOS.platform/Developer/SDKs";

         if (FileSystem.exists(dev_path)) 
         {
            var best = "";
               var files = FileSystem.readDirectory(dev_path);
               var extract_version = ~/^iPhoneOS(.*).sdk$/;

               for(file in files) 
               {
               if (extract_version.match(file)) 
               {
                  var ver = extract_version.matched(1);
                        if (ver > best)
                           best = ver;
                     }
               }

               if (best != "")
                     project.environment.set("IPHONE_VER", best);
         }
         }
   }

   public function getProvisioningFile():String 
   {
      var path = PathHelper.expand("~/Library/MobileDevice/Provisioning Profiles");
      var files = FileSystem.readDirectory(path);

      for(file in files) 
      {
         if (Path.extension(file) == "mobileprovision") 
         {
            return path + "/" + file;
         }
      }

      return "";
   }

   private function initialize(project:NMEProject):Void 
   {
      if (!initialized) 
      {
         getIOSVersion(project);

         initialized = true;
      }
   }

   public function launch(project:NMEProject, workingDirectory:String):Void 
   {
      initialize(project);

      var configuration = "Release";
      if (project.debug) 
         configuration = "Debug";

      Log.verbose("Configuration :  " + configuration);

      if (project.targetFlags.exists("simulator")) 
      {
         var applicationPath = "";

         if (Path.extension(workingDirectory) == "app" || Path.extension(workingDirectory) == "ipa") 
         {
            applicationPath = workingDirectory;
         }
         else
         {
            applicationPath = workingDirectory + "/build/" + configuration + "-iphonesimulator/" + project.app.file + ".app";
         }

         Log.verbose("Boot simulator...");
         waitBooted();

         Log.verbose("Uninstall old versions ...");
         ProcessHelper.runCommand("", "xcrun", ["simctl", "uninstall", "booted", applicationPath ], true, true);

         Log.verbose("Install app...");
         ProcessHelper.runCommand("", "xcrun", ["simctl", "install", "booted", applicationPath ]);
        
         Log.verbose("Launch " + project.app.packageName + " ...");
         var args = ["simctl", "launch", "booted", project.app.packageName ];
         if (wantLldb())
            args.insert(2, "-w");
         var lines = ProcessHelper.getOutput("xcrun", args);
         var procIdMatch = ~/: (\d+)/;
         if (lines.length!=1 || !procIdMatch.match(lines[0]))
            Log.verbose("Could not determine process Id of started application (" + lines + ")" );
         else
         {
            launchPid = Std.parseInt(procIdMatch.matched(1));
            Log.verbose("Launched pid=" + launchPid );
         }
      }
      else
      {
         var applicationPath = "";

         if (Path.extension(workingDirectory) == "app" || Path.extension(workingDirectory) == "ipa") 
            applicationPath = workingDirectory;
         else
            applicationPath = workingDirectory + "/build/" + configuration + "-iphoneos/" + project.app.file + ".app";

         Log.verbose("Application path " + applicationPath);

            var launcher = CommandLineTools.nme +  "/tools/nme/bin/fruitstrap";
            //var launcher = PathHelper.findTemplate(project.templatePaths, "bin/fruitstrap");
           Sys.command("chmod", [ "+x", launcher ]);

           if (project.debug) 
           {
               ProcessHelper.runCommand("", launcher, [ "install", "--debug", "--timeout", "5", "--bundle", FileSystem.fullPath(applicationPath) ]);
           }
           else
           {
               ProcessHelper.runCommand("", launcher, [ "install", "--debug", "--timeout", "5", "--bundle", FileSystem.fullPath(applicationPath) ]);
           }
      }
   }

   public function sign(project:NMEProject, workingDirectory:String, entitlementsPath:String):Void 
   {
        initialize(project);

        var configuration = "Release";

        if (project.debug) 
        {
            configuration = "Debug";
        }

        var commands = [ "-s", "iPhone Developer" ];

        if (entitlementsPath != null) 
        {
           commands.push("--entitlements");
           commands.push(entitlementsPath);
        }

        var applicationPath = "build/" + configuration + "-iphoneos/" + project.app.file + ".app";
        commands.push(applicationPath);

        ProcessHelper.runCommand(workingDirectory, "codesign", commands, true, true);
   }






   /*private function updateLaunchImage() {
      var destination = buildDirectory + "/ios";
      PathHelper.mkdir(destination);

      var has_launch_image = false;
      if (launchImages.length > 0) has_launch_image = true;

      for(launchImage in launchImages) 
      {
         var splitPath = launchImage.name.split("/");
         var path = destination + "/" + splitPath[splitPath.length - 1];
         FileHelper.copyFile(launchImage.name, path, context, false);
      }

      context.HAS_LAUNCH_IMAGE = has_launch_image;

   }*/

}
