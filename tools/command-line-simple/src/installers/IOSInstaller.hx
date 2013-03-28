package installers;

import data.Asset;
import data.NDLL;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import neko.Lib;
import Sys;

class IOSInstaller extends InstallerBase 
{
   override function build():Void 
   {
      //throw "Build not supported on IOS target - please build from Xcode";
      var platformName:String = "iphoneos";

      if (targetFlags.exists("simulator")) 
      {
         platformName = "iphonesimulator";
      }

      var configuration:String = "Release";

      if (debug) 
      {
         configuration = "Debug";
      }

      var iphoneVersion:String = defines.get("IPHONE_VER");

      //runCommand(buildDirectory + "/iphone", "xcodebuild", [ "PLATFORM_NAME=" + platformName, "-sdk " + platformName + iphoneVersion, "-configuration " + configuration ] );
      runCommand(buildDirectory + "/iphone", "xcodebuild", [ "-configuration", configuration, "PLATFORM_NAME=" + platformName, "SDKROOT=" + platformName + iphoneVersion ] );
   }

   private override function generateContext():Void 
   {
      super.generateContext();

      context.HAS_ICON = false;

      if (defines.exists("IPHONE_VER") && Std.parseFloat(defines.get("IPHONE_VER")) >= 5 && !targetFlags.exists("simulator")) 
      {
         context.CURRENT_ARCHS = "$(ARCHS_STANDARD_32_BIT) armv6";

      }
      else
      {
         context.CURRENT_ARCHS = "$(ARCHS_STANDARD_32_BIT)";
      }

      switch(defines.get("WIN_ORIENTATION")) 
      {
         case "landscape":

            context.IPHONE_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string></array>";

         case "portrait":

            context.IPHONE_ORIENTATION = "<array><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";

         default:

            context.IPHONE_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
      }

      context.ADDL_PBX_BUILD_FILE = "";
      context.ADDL_PBX_FILE_REFERENCE = "";
      context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE = "";
      context.ADDL_PBX_FRAMEWORK_GROUP = "";

      for(dependencyName in dependencyNames) 
      {
         if (Path.extension(dependencyName) == "framework") 
         {
            var frameworkID = "11C0000000000018" + Utils.getUniqueID();
            var fileID = "11C0000000000018" + Utils.getUniqueID();

            context.ADDL_PBX_BUILD_FILE += "      " + frameworkID + " /* " + dependencyName + " in Frameworks */ = {isa = PBXBuildFile; fileRef = " + fileID + " /* " + dependencyName + " */; };\n";
            context.ADDL_PBX_FILE_REFERENCE += "      " + fileID + " /* " + dependencyName + " */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = " + dependencyName + "; path = System/Library/Frameworks/" + dependencyName + "; sourceTree = SDKROOT; };\n";
            context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE += "            " + frameworkID + " /* " + dependencyName + " in Frameworks */,\n";
            context.ADDL_PBX_FRAMEWORK_GROUP += "            " + fileID + " /* " + dependencyName + " */,\n";
         }
      }

      context.HXML_PATH = NME + "/tools/command-line-simple/iphone/haxe/Build.hxml";

      updateIcon();
   }

   private override function onCreate():Void 
   {
      ndlls.push(new NDLL("curl_ssl", "nme", false));
      ndlls.push(new NDLL("png", "nme", false));
      ndlls.push(new NDLL("jpeg", "nme", false));
      ndlls.push(new NDLL("z", "nme", false));

      for(asset in assets) 
      {
         asset.resourceName = asset.flatName;
      }

      if (!defines.exists("IPHONE_VER")) 
      {
         var dev_path = "/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/";

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
                     defines.set("IPHONE_VER", best);
         }
         }

      //setDefault("IPHONE_VER", "4.3");
   }

   override function run():Void 
   {
      if (!targetFlags.exists("simulator")) 
      {
         runCommand("", "open", [ buildDirectory + "/iphone/" + defines.get("APP_FILE") + ".xcodeproj" ] );

      }
      else
      {
         var configuration:String = "Release";

         if (debug) 
         {
            configuration = "Debug";
         }

         var applicationPath:String = buildDirectory + "/iphone/build/" + configuration + "-iphonesimulator/" + defines.get("APP_TITLE") + ".app";
         //var targetPath:String = Sys.getEnv("HOME") + "/Library/Application Support/iPhone Simulator/4.3.2/Applications/" + defines.get("APP_PACKAGE") + "/" + defines.get("APP_TITLE") + ".app";
         //mkdir(targetPath);
         //recursiveCopy(applicationPath, targetPath);
         var family:String = "iphone";

         if (targetFlags.exists("ipad")) 
         {
            family = "ipad";
         }

         var launcher:String = NME + "/tools/command-line-simple/iphone/iphonesim";

         Sys.command("chmod", [ "755", launcher ]);

         runCommand("", launcher, [ "launch", FileSystem.fullPath(applicationPath), defines.get("IPHONE_VER"), family ] );
         //runCommand("", "open", [ "/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app" ] );
      }
   }

   override function update():Void 
   {
      var destination:String = buildDirectory + "/iphone/";

      mkdir(destination);
      mkdir(destination + "/haxe");
      mkdir(destination + "/haxe/nme/installer");

      copyFile(NME + "/tools/command-line-simple/haxe/nme/installer/Assets.hx", destination + "/haxe/nme/installer/Assets.hx");
      recursiveCopy(NME + "/tools/command-line-simple/iphone/haxe", destination + "/haxe");
      recursiveCopy(NME + "/tools/command-line-simple/iphone/Classes", destination + "Classes");
      recursiveCopy(NME + "/tools/command-line-simple/iphone/PROJ.xcodeproj", destination + defines.get("APP_FILE") + ".xcodeproj");
      copyFile(NME + "/tools/command-line-simple/iphone/PROJ-Info.plist", destination + defines.get("APP_FILE") + "-Info.plist");
      generateSWFClasses(NME + "/tools/command-line-simple/resources/SWFClass.mtt", destination + "/haxe");

      mkdir(destination + "lib");

      for(ndll in ndlls) 
      {
         copyIfNewer(ndll.getSourcePath("iPhone", "lib" + ndll.name + ".iphoneos.a"), destination + "lib/lib" + ndll.name + ".iphoneos.a" );
         copyIfNewer(ndll.getSourcePath("iPhone", "lib" + ndll.name + ".iphonesim.a"), destination + "lib/lib" + ndll.name + ".iphonesim.a" );
      }

      mkdir(destination + "assets");

      for(asset in assets) 
      {
         if (asset.type != Asset.TYPE_TEMPLATE) 
         {
            mkdir(Path.directory(destination + "assets/" + asset.flatName));
            copyIfNewer(asset.sourcePath, destination + "assets/" + asset.flatName);

         }
         else
         {
            copyFile(asset.sourcePath, destination + asset.targetPath);
         }
      }
   }

   function updateIcon() 
   {
      var destination:String = buildDirectory + "/iphone/";
      mkdir(destination);

      var has_icon = true;

      for(i in 0...4) 
      {
         var iname = ["Icon.png", "Icon@2x.png", "Icon-72.png", "Icon-Small.png" ][i];
         var size = [57,114,72,50][i];
         var name = destination + "/" + iname;

         if (!icons.updateIcon(size, size, name)) 
         {
            has_icon = false;
         }
      }

      context.HAS_ICON = has_icon;
   }

   override function useFullClassPaths() { return true; }
}
