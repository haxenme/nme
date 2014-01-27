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

   public static function build(project:NMEProject, workingDirectory:String, additionalArguments:Array<String> = null):Void 
   {
      initialize(project);

      var platformName = "iphoneos";

        if (project.targetFlags.exists("simulator")) 
        {
            platformName = "iphonesimulator";
        }

        var configuration = "Release";

        if (project.debug) 
        {
            configuration = "Debug";
        }

        var iphoneVersion = project.environment.get("IPHONE_VER");
        var commands = [ "-configuration", configuration, "PLATFORM_NAME=" + platformName, "SDKROOT=" + platformName + iphoneVersion ];

        if (project.targetFlags.exists("simulator")) 
        {
            commands.push("-arch");
            commands.push("i386");
        }

        if (additionalArguments != null) 
        {
           commands = commands.concat(additionalArguments);
        }

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
        {
            configuration = "Debug";
        }

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
         {
            family = "ipad";
         }

         //var launcher = PathHelper.findTemplate(project.templatePaths, "bin/ios-sim");
         var launcher = CommandLineTools.nme +  "/tools/command-line/bin/ios-sim";
         Sys.command("chmod", [ "+x", launcher ]);

         ProcessHelper.runCommand("", launcher, [ "launch", FileSystem.fullPath(applicationPath), "--sdk", project.environment.get("IPHONE_VER"), "--family", family ] );
      }
      else
      {
         var applicationPath = "";

         if (Path.extension(workingDirectory) == "app" || Path.extension(workingDirectory) == "ipa") 
         {
            applicationPath = workingDirectory;
         }
         else
         {
            applicationPath = workingDirectory + "/build/" + configuration + "-iphoneos/" + project.app.file + ".app";
         }

            var launcher = PathHelper.findTemplate(project.templatePaths, "bin/fruitstrap");
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
   var armv6:Bool;
   var armv7:Bool;
   public function new(inProject:NMEProject)
   {
      armv6 = armv7 = false;
      super(inProject);
   }

   override public function build():Void 
   {
      var targetDirectory = PathHelper.combine(project.app.path, "ios");

      IOSHelper.build(project, project.app.path + "/ios");

        if (!project.targetFlags.exists("simulator")) 
        {
            var entitlements = targetDirectory + "/" + project.app.file + "/" + project.app.file + "-Entitlements.plist";

            IOSHelper.sign(project, targetDirectory + "/bin", entitlements);
        }
   }

   override public function clean():Void 
   {
      var targetPath = project.app.path + "/ios";

      if (FileSystem.exists(targetPath)) 
      {
         PathHelper.removeDirectory(targetPath);
      }
   }

   override public function display():Void 
   {
      var hxml = PathHelper.findTemplate(project.templatePaths, "ios/PROJ/haxe/Build.hxml");
      var template = new Template(File.getContent(hxml));
      Sys.println(template.execute(generateContext()));
   }

   function getHaxeBase()
   {
      return  "ios/" + project.app.file + "/haxe";
   }

   override private function generateContext():Dynamic 
   {
      project.classPaths = PathHelper.relocatePaths(project.classPaths, PathHelper.combine(project.app.path, getHaxeBase() ));

      if (project.targetFlags.exists("xml")) 
      {
         project.haxeflags.push("-xml " + project.app.path + "/ios/types.xml");
      }

      var context = project.templateContext;

      context.HAS_ICON = false;
      context.HAS_LAUNCH_IMAGE = false;
      context.OBJC_ARC = false;

      context.linkedLibraries = [];

      for(dependency in project.dependencies) 
      {
         if (!StringTools.endsWith(dependency, ".framework")) 
         {
            context.linkedLibraries.push(dependency);
         }
      }

     
      var valid_archs = new Array<String>();
      armv6 = false;
      armv7 = false;
      var architectures = project.architectures;

      var config = project.iosConfig;

      if ( (config.deviceConfig & IOSConfig.IPHONE) > 0 )
      {
         if (config.deployment < 5) 
            ArrayHelper.addUnique(architectures, Architecture.ARMV6);
      }

      if (architectures.length == 0) 
         architectures.push( Architecture.ARMV7 );

      for(architecture in project.architectures) 
      {
         switch(architecture) 
         {
            case ARMV6: valid_archs.push("armv6"); armv6 = true;
            case ARMV7: valid_archs.push("armv7"); armv7 = true;
            default:
         }
      }

      context.CURRENT_ARCHS = "( " + valid_archs.join(",") + ") ";

      valid_archs.push("i386");

      context.VALID_ARCHS = valid_archs.join(" ");
      context.THUMB_SUPPORT = armv6 ? "GCC_THUMB_SUPPORT = NO;" : "";

      var requiredCapabilities = [];

      if (armv7 && !armv6) 
      {
         requiredCapabilities.push( { name: "armv7", value: true } );
      }

      context.REQUIRED_CAPABILITY = requiredCapabilities;
      context.ARMV6 = armv6;
      context.ARMV7 = armv7;
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

      context.HXML_PATH = PathHelper.findTemplate(project.templatePaths, "ios/PROJ/haxe/Build.hxml");
      context.PRERENDERED_ICON = config.prerenderedIcon;

      /*var assets = new Array<Asset>();
      for(asset in project.assets) 
      {
         var newAsset = asset.clone();

         assets.push();

      }*/

      //updateIcon();
      //updateLaunchImage();
      return context;
   }

   override public function run(arguments:Array<String>):Void 
   {
      IOSHelper.launch(project, PathHelper.combine(project.app.path, "ios"));
   }

   override public function update():Void 
   {
      var nmeLib = new Haxelib("nme");

      //project.ndlls.push(new NDLL("curl_ssl", nmeLib, false));
      //project.ndlls.push(new NDLL("png", nmeLib, false));
      //project.ndlls.push(new NDLL("jpeg", nmeLib, false));
      //project.ndlls.push(new NDLL("freetype", nmeLib, false));

      for(asset in project.assets) 
         asset.resourceName = asset.flatName;

      var context = generateContext();

      var targetDirectory = PathHelper.combine(project.app.path, "ios");
      var projectDirectory = targetDirectory + "/" + project.app.file + "/";

      PathHelper.mkdir(targetDirectory);
      PathHelper.mkdir(projectDirectory);
      PathHelper.mkdir(projectDirectory + "/haxe");
      PathHelper.mkdir(projectDirectory + "/haxe/nme/installer");

      var iconNames = [ "Icon.png", "Icon@2x.png", "Icon-72.png", "Icon-72@2x.png" ];
      var iconSizes = [ 57, 114, 72, 144 ];

      context.HAS_ICON = true;

      for(i in 0...iconNames.length) 
      {
         if (!IconHelper.createIcon(project.icons, iconSizes[i], iconSizes[i], PathHelper.combine(projectDirectory, iconNames[i]))) 
         {
            context.HAS_ICON = false;
         }
      }

      for(splashScreen in project.splashScreens) 
      {
         FileHelper.copyFile(splashScreen.path, PathHelper.combine(projectDirectory, Path.withoutDirectory(splashScreen.path)));
         context.HAS_LAUNCH_IMAGE = true;
      }

      FileHelper.copyFileTemplate(project.templatePaths, "haxe/nme/AssetData.hx", projectDirectory + "/haxe/nme/AssetData.hx", context);
      FileHelper.recursiveCopyTemplate(project.templatePaths, "ios/PROJ/haxe", projectDirectory + "/haxe", context);
      FileHelper.recursiveCopyTemplate(project.templatePaths, "ios/PROJ/Classes", projectDirectory + "/Classes", context);
      FileHelper.copyFileTemplate(project.templatePaths, "ios/PROJ/PROJ-Entitlements.plist", projectDirectory + "/" + project.app.file + "-Entitlements.plist", context);
      FileHelper.copyFileTemplate(project.templatePaths, "ios/PROJ/PROJ-Info.plist", projectDirectory + "/" + project.app.file + "-Info.plist", context);
      FileHelper.copyFileTemplate(project.templatePaths, "ios/PROJ/PROJ-Prefix.pch", projectDirectory + "/" + project.app.file + "-Prefix.pch", context);
      FileHelper.recursiveCopyTemplate(project.templatePaths, "ios/PROJ.xcodeproj", targetDirectory + "/" + project.app.file + ".xcodeproj", context);

      //SWFHelper.generateSWFClasses(project, projectDirectory + "/haxe");
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
               var debugLib = PathHelper.getLibraryPath(ndll, "iPhone", "lib", libExt);
               var releaseDest = projectDirectory + "/lib/" + arch + "/lib" + ndll.name + ".a";
               var debugDest = projectDirectory + "/lib/" + arch + "-debug/lib" + ndll.name + ".a";

               FileHelper.copyIfNewer(releaseLib, releaseDest);

               if (FileSystem.exists(debugLib)) 
               {
                  FileHelper.copyIfNewer(debugLib, debugDest);

               } else if (FileSystem.exists(debugDest)) 
               {
                  FileSystem.deleteFile(debugDest);
               }
            }
         }
      }

      PathHelper.mkdir(projectDirectory + "/assets");

      for(asset in project.assets) 
      {
         if (!asset.embed)
         {
            PathHelper.mkdir(Path.directory(projectDirectory + "/assets/" + asset.flatName));
            FileHelper.copyIfNewer(asset.sourcePath, projectDirectory + "/assets/" + asset.flatName);
            FileHelper.copyIfNewer(asset.sourcePath, projectDirectory + "haxe/" + asset.sourcePath);
         }
      }

        if (project.command == "update" && PlatformHelper.hostPlatform == Platform.MAC) 
        {
            ProcessHelper.runCommand("", "open", [ targetDirectory + "/" + project.app.file + ".xcodeproj" ] );
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
