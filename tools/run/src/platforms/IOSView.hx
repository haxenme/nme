package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class IOSView extends IOSPlatform
{
   var component:String;

   public function new(inProject:NMEProject)
   {
      super(inProject);
      component = inProject.app.file;
   }

   override public function getPlatformDir() : String { return "ios-view"; }
   override public function getOutputDir() { return targetDir + "/project"; }
   function getSdkDir()     { return targetDir + "/" + project.app.file; }


   override public function updateOutputDir():Void 
   {
      PathHelper.mkdir(targetDir);

      PathHelper.mkdir(haxeDir);
      PathHelper.mkdir(haxeDir + "/cpp");

      copyTemplate("ios-view/FrameworkInterface.mm", haxeDir+"/cpp/FrameworkInterface.mm");

      copyTemplateDir("ios-view/build", haxeDir);

      copyTemplate("ios-view/HEADER.h",  haxeDir+"/cpp/FrameworkHeader.h" );
   }

   override public function runHaxe()
   {
      ProcessHelper.runCommand(haxeDir, "make", [] );
   }

   override function postBuild()
   {
     var sdk = getSdkDir();
     var name = project.app.file;
     copyTemplate("ios-view/HEADER.h", sdk+"/"+name + ".h" );
     copyTemplate("ios-view/CLASS.mm",  sdk+"/"+name + ".mm" );
     // Copy libs?
   }

   override function generateContext(context:Dynamic)
   {
      var name = project.app.file;
      var outputDirectory = '$targetDir/$name/';

      if (project.debug)
         project.haxeflags.push("-debug");
 
      context.COMPONENT = component;

      var libExts = new Array<String>();
      if (hasArch(ARMV6)) libExts.push(".iphoneos.a");
      if (hasArch(ARMV7)) libExts.push(".iphoneos-v7.a");
      libExts.push(".iphonesim.a");

      var appLibs = new Array<String>();
      var dbg = project.debug ? "-debug" : "";
      for(ext in libExts)
         appLibs.push("cpp/ApplicationMain" + dbg + ext);

      for(ndll in project.ndlls) 
      {
         if (ndll.haxelib != null) 
         {
            for(ext in libExts)
            {
               var releaseLib = PathHelper.getLibraryPath(ndll, "iPhone", "lib", ext);
               appLibs.push(releaseLib);
            }
         }
      }
      context.APP_LIBS = appLibs.join(" ");

      //context.DEST_PATH = PathHelper.relocatePath('$outputDirectory/Versions/A/$name', buildDir);
      context.DEST_PATH = PathHelper.relocatePath('$outputDirectory/lib$name.a', haxeDir);
      context.CLASS_NAME = name;

      context.RESOURCES = "";
   }

}
