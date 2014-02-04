package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;
import NMEProject;

import haxe.io.Path;
import sys.io.Process;
import sys.FileSystem;

class IOSHelper 
{
   private static var initialized = false;

   public static function xcodeBuild(project:NMEProject, workingDirectory:String, additionalArguments:Array<String> = null):Void 
   {
      initialize(project);

      var platformName = "iphoneos";

        if (project.targetFlags.exists("simulator")) 
            platformName = "iphonesimulator";

        var configuration = "Release";

        if (project.debug) 
            configuration = "Debug";

        var iphoneVersion = project.environment.get("IPHONE_VER");
        var commands = [ "-configuration", configuration, "PLATFORM_NAME=" + platformName, "SDKROOT=" + platformName + iphoneVersion ];

        if (project.targetFlags.exists("simulator")) 
        {
            commands.push("-arch");
            commands.push("i386");
        }

        if (additionalArguments != null) 
           commands = commands.concat(additionalArguments);

        ProcessHelper.runCommand(workingDirectory, "xcodebuild", commands);
        //ProcessHelper.runCommand(workingDirectory + "/" + project , "xcodebuild", commands);
   }

   public static function getSDKDirectory(project:NMEProject):String 
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

   private static function getIOSVersion(project:NMEProject):Void 
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

   public static function getProvisioningFile():String 
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

   private static function initialize(project:NMEProject):Void 
   {
      if (!initialized) 
      {
         getIOSVersion(project);

         initialized = true;
      }
   }

   public static function launch(project:NMEProject, workingDirectory:String):Void 
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

         var family = "iphone";

         if (project.targetFlags.exists("ipad")) 
            family = "ipad";

         //var launcher = PathHelper.findTemplate(project.templatePaths, "bin/ios-sim");
         var launcher = CommandLineTools.nme +  "/tools/command-line/bin/ios-sim";
         Sys.command("chmod", [ "+x", launcher ]);

         ProcessHelper.runCommand("", launcher, [ "launch", FileSystem.fullPath(applicationPath), "--sdk", project.environment.get("IPHONE_VER"), "--family", family ] );
      }
      else
      {
         var applicationPath = "";

         if (Path.extension(workingDirectory) == "app" || Path.extension(workingDirectory) == "ipa") 
            applicationPath = workingDirectory;
         else
            applicationPath = workingDirectory + "/build/" + configuration + "-iphoneos/" + project.app.file + ".app";

         Log.verbose("Application path " + applicationPath);

            var launcher = CommandLineTools.nme +  "/tools/command-line/bin/fruitstrap";
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

   public static function sign(project:NMEProject, workingDirectory:String, entitlementsPath:String):Void 
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
}


class IOSPlatform extends Platform
{
   var buildV6:Bool;
   var buildV7:Bool;
   var buildI386:Bool;
  

   public function new(inProject:NMEProject)
   {
      super(inProject);

      for(asset in project.assets) 
         asset.resourceName = asset.flatName;
      project.haxeflags.push("-cpp cpp");

      var architectures = project.architectures;
      var config = project.iosConfig;
      // If we support iphones with deployment < 5, we must support armv6 ...
      if ( (config.deviceConfig & IOSConfig.IPHONE) > 0 && config.deployment<5)
          ArrayHelper.addUnique(architectures, Architecture.ARMV6);
      else
          ArrayHelper.addUnique(architectures, Architecture.ARMV7);

      ArrayHelper.addUnique(architectures, Architecture.I386);
   
      buildV6 = buildV7 = buildI386 = false;

      if (project.command == "xcode")
      {
         var arch = project.localDefines.get("xcodearch");
         Log.verbose("Target flags: " + arch );
         switch(arch)
         {
            case "i386":
                buildI386 = true;
            case "armv6":
                if (hasArch(Architecture.ARMV6))
                   Log.error("Armv6 not supported");
                buildV6 = true;
            case "armv7":
                if (hasArch(Architecture.ARMV6))
                   Log.error("Armv6 not supported");
                buildV7 = true;
            default:
                Log.error("Unknown arch " + arch);
         }
      }
      else
      {
         var build = project.targetFlags;
         Log.verbose("Target flags: " + build);

         if (build.exists("simulator") || build.exists("ios") ) 
            buildI386 = true;

         if (build.exists("iphoneos") || build.exists("ios")) 
         {
            buildV6 = hasArch(Architecture.ARMV6);
            buildV7 = hasArch(Architecture.ARMV7);
         }
      }
      Log.verbose("Valid Archs: " + architectures );
   }

   override public function buildPackage():Void 
   {
      IOSHelper.xcodeBuild(project, targetDir);

      if (buildV6 || buildV7)
      {
          var entitlements = targetDir + "/" + project.app.file + "/" + project.app.file + "-Entitlements.plist";

          IOSHelper.sign(project, targetDir + "/bin", entitlements);
      }
   }

   override public function getBinName() : String { return "iPhone"; }
   override public function getAssetDir() { return getOutputDir() + "/assets"; }
   override public function getPlatformDir() : String { return "ios"; }


   override private function generateContext(context:Dynamic)
   {

      context.HAS_ICON = false;
      context.HAS_LAUNCH_IMAGE = false;
      context.OBJC_ARC = false;
      context.PROJECT_DIRECTORY = Sys.getCwd();
      context.APP_FILE = project.app.file;

      context.linkedLibraries = [];

      for(dependency in project.dependencies) 
      {
         if (!StringTools.endsWith(dependency, ".framework")) 
            context.linkedLibraries.push(dependency);
      }

     
      var valid_archs = new Array<String>();
      var current_archs = new Array<String>();

      var config = project.iosConfig;

      for(architecture in project.architectures) 
      {
         switch(architecture) 
         {
            case ARMV6: valid_archs.push("armv6"); current_archs.push("armv6");
            case ARMV7: valid_archs.push("armv7"); current_archs.push("armv7");
            case I386: valid_archs.push("i386");
            default:
         }
      }

      context.CURRENT_ARCHS = "( " + current_archs.join(",") + ") ";

      context.VALID_ARCHS = valid_archs.join(" ");
      context.THUMB_SUPPORT = hasArch(ARMV6) ? "GCC_THUMB_SUPPORT = NO;" : "";
      context.KEY_STORE_IDENTITY = "iPhone Developer";

      var requiredCapabilities = [];

      if (hasArch(ARMV7) && !hasArch(ARMV6)) 
         requiredCapabilities.push( { name: "armv7", value: true } );

      context.REQUIRED_CAPABILITY = requiredCapabilities;
      context.ARMV6 = hasArch(ARMV6);
      context.ARMV7 = hasArch(ARMV7);
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
      context.IOS_LINKER_FLAGS = config.linkerFlags.split(" ").join(", ");

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

      for(dependency in project.dependencies) 
      {
         if (Path.extension(dependency) == "framework") 
         {
            var frameworkID = "11C0000000000018" + StringHelper.getUniqueID();
            var fileID = "11C0000000000018" + StringHelper.getUniqueID();

            context.ADDL_PBX_BUILD_FILE += "      " + frameworkID + " /* " + dependency + " in Frameworks */ = {isa = PBXBuildFile; fileRef = " + fileID + " /* " + dependency + " */; };\n";
            context.ADDL_PBX_FILE_REFERENCE += "      " + fileID + " /* " + dependency + " */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = " + dependency + "; path = System/Library/Frameworks/" + dependency + "; sourceTree = SDKROOT; };\n";
            context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE += "            " + frameworkID + " /* " + dependency + " in Frameworks */,\n";
            context.ADDL_PBX_FRAMEWORK_GROUP += "            " + fileID + " /* " + dependency + " */,\n";
         }
      }

      context.PRERENDERED_ICON = config.prerenderedIcon;

      //updateIcon();
      //updateLaunchImage();
   }


   override public function runHaxe()
   {
      var args = project.debug ? ["build.hxml","-debug"] : ["build.hxml"];

      if (buildV6)
         ProcessHelper.runCommand(haxeDir, "haxe", args.concat(["-D", "HXCPP_ARMV6", "-D", "iphoneos"]));

      if (buildV7)
         ProcessHelper.runCommand(haxeDir, "haxe", args.concat(["-D", "HXCPP_ARMV7", "-D", "iphoneos"]));

      if (buildI386)
         ProcessHelper.runCommand(haxeDir, "haxe", args.concat(["-D", "iphonesim"]));
   }


   override public function copyBinary():Void 
   {
      var dbg = project.debug ? "-debug" : "";
      var projectDirectory = getOutputDir();

      if (buildV6)
         FileHelper.copyIfNewer(haxeDir + "/cpp/ApplicationMain" + dbg + ".iphoneos.a",
                      projectDirectory + "/lib/armv6" + dbg + "/libApplicationMain.a" );

      if (buildV7)
         FileHelper.copyIfNewer(haxeDir + "/cpp/ApplicationMain" + dbg + ".iphoneos-v7.a",
                      projectDirectory + "/lib/armv7" + dbg + "/libApplicationMain.a" );

      if (buildI386)
         FileHelper.copyIfNewer(haxeDir + "/cpp/ApplicationMain" + dbg + ".iphonesim.a",
                      projectDirectory + "/lib/i386" + dbg + "/libApplicationMain.a" );
   }


   override public function run(arguments:Array<String>):Void 
   {
      IOSHelper.launch(project, targetDir);
   }

   override public function updateOutputDir():Void 
   {
      var nmeLib = new Haxelib("nme");

      var projectDirectory = getOutputDir();

      PathHelper.mkdir(targetDir);

     var iconNames = [ "Icon.png", "Icon@2x.png", "Icon-60.png", "Icon-60@2x.png", "Icon-72.png", "Icon-72@2x.png", "Icon-76.png", "Icon-76@2x.png" ];
     var iconSizes = [ 57, 114, 60, 120, 72, 144, 76, 152 ];

     context.HAS_ICON = true;

     for (i in 0...iconNames.length)
     {
         if (!IconHelper.createIcon(project.icons, iconSizes[i], iconSizes[i], PathHelper.combine(projectDirectory, iconNames[i])))
            context.HAS_ICON = false;
     }

      var splashScreenNames = [ "Default.png", "Default@2x.png", "Default-568h@2x.png", "Default-Portrait.png",
                                "Default-Landscape.png", "Default-Portrait@2x.png", "Default-Landscape@2x.png" ];
      var splashScreenWidth = [ 320, 640, 640, 768, 1024, 1536, 2048 ];
      var splashScreenHeight = [ 480, 960, 1136, 1024, 768, 2048, 1536 ];

      for (i in 0...splashScreenNames.length)
      {
         var width = splashScreenWidth[i];
         var height = splashScreenHeight[i];
         var match = false;

         for(splashScreen in project.splashScreens)
         {
            if (splashScreen.width == width && splashScreen.height == height && Path.extension(splashScreen.path) == "png")
            {
               FileHelper.copyIfNewer(splashScreen.path, PathHelper.combine(projectDirectory, splashScreenNames[i]));
               match = true;
               break;
            }
         }

         if (!match)
         {
            var dest = PathHelper.combine(projectDirectory, splashScreenNames[i]);
            if (!FileSystem.exists(dest))
            {
               var bitmapData = new nme.display.BitmapData(width, height, false, (0xFF << 24) | (project.window.background & 0xFFFFFF));
               File.saveBytes(dest, bitmapData.encode("png"));
            }
         }
      }
      context.HAS_LAUNCH_IMAGE = true;


      // Do not update if we are running from inside xcode
      if (project.command!="xcode")
      {
         copyTemplateDir("ios/PROJ/Classes", projectDirectory + "/Classes");
         copyTemplate("ios/PROJ/PROJ-Entitlements.plist", projectDirectory + "/" + project.app.file + "-Entitlements.plist");
         copyTemplate("ios/PROJ/PROJ-Info.plist", projectDirectory + "/" + project.app.file + "-Info.plist");
         copyTemplate("ios/PROJ/PROJ-Prefix.pch", projectDirectory + "/" + project.app.file + "-Prefix.pch");
         copyTemplateDir("ios/PROJ.xcodeproj", targetDir + "/" + project.app.file + ".xcodeproj");
      }

      if (project.command == "update" && PlatformHelper.hostPlatform == Platform.MAC) 
         ProcessHelper.runCommand("", "open", [ targetDir + "/" + project.app.file + ".xcodeproj" ] );
   }

   override public function updateLibs()
   {
      var projectDirectory = getOutputDir();

      PathHelper.mkdir(projectDirectory + "/lib");

      for(archID in 0...3) 
      {
         var arch = [ "armv6", "armv7", "i386" ][archID];

         if (arch == "armv6" && !context.ARMV6)
            continue;

         if (arch == "armv7" && !context.ARMV7)
            continue;

         var libExt = [ ".iphoneos.a", ".iphoneos-v7.a", ".iphonesim.a" ][archID];

         PathHelper.mkdir(projectDirectory + "/lib/" + arch);
         PathHelper.mkdir(projectDirectory + "/lib/" + arch + "-debug");

         for(ndll in project.ndlls) 
         {
            if (ndll.haxelib != null) 
            {
               var releaseLib = PathHelper.getLibraryPath(ndll, "iPhone", "lib", libExt);
               var releaseDest = projectDirectory + "/lib/" + arch + "/lib" + ndll.name + ".a";

               FileHelper.copyIfNewer(releaseLib, releaseDest);
            }
         }
      }
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
