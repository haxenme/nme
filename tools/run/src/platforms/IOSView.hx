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
   override public function getOutputDir() { return targetDir + "/" + project.app.file; }

   override public function updateBuildDir():Void 
   {
      super.updateBuildDir();
      copyTemplate("ios-view/FrameworkInterface.mm", haxeDir+"/cpp/FrameworkInterface.mm");
      copyTemplate("ios-view/HEADER.h",  haxeDir+"/cpp/FrameworkHeader.h" );
   }

   override public function copyBinary():Void
   {
   }

   override public function run(arguments:Array<String>):Void { }

   override public function updateLibs() { }

   override public function updateAssets() { }
  
   override public function updateOutputDir():Void 
   {
      PathHelper.mkdir(getOutputDir());
   }

   override function postBuild()
   {
     var sdk = getOutputDir();
     var name = project.app.file;
     copyTemplate("ios-view/HEADER.h", sdk+"/"+name + ".h" );
     copyTemplate("ios-view/CLASS.mm",  sdk+"/"+name + ".mm" );
   }

   override public function buildPackage():Void 
   {
      var libExts = new Array<String>();
      if (buildV6) libExts.push(".iphoneos.a");
      if (buildV7) libExts.push(".iphoneos-v7.a");
      if (buildI386) libExts.push(".iphonesim.a");


      var appLibs = new Array<String>();
      var dbg = project.debug ? "-debug" : "";
      for(ext in libExts)
      {
         appLibs.push(targetDir + "/haxe/cpp/ApplicationMain" + dbg + ext);

         for(ndll in project.ndlls) 
            if (ndll.haxelib != null) 
            {
               var releaseLib = PathHelper.getLibraryPath(ndll, "iPhone", "lib", ext);
               appLibs.push(releaseLib);
            }
      }

      var dest = getOutputDir() + "/lib" + project.app.file + ".a";
      var args = ["-static","-o", dest].concat(appLibs);
      ProcessHelper.runCommand("", "libtool", args);
   }




   override function generateContext(context:Dynamic)
   {
      var name = project.app.file;
      var outputDirectory = '$targetDir/$name/';

      if (project.debug)
         project.haxeflags.push("-debug");
 
      context.COMPONENT = component;

       //context.DEST_PATH = PathHelper.relocatePath('$outputDirectory/Versions/A/$name', buildDir);
      context.DEST_PATH = PathHelper.relocatePath('$outputDirectory/lib$name.a', haxeDir);
      context.CLASS_NAME = name;

      context.RESOURCES = "";
   }

}
