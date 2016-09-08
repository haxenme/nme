package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;
import NMEProject;

import haxe.io.Path;
import sys.io.Process;
import sys.FileSystem;



class WatchPlatform extends Platform
{
   private static var initialized = false;

   var simulatorUid:String;
   var launchPid:Int;
   var redirectTrace:Bool;
   var linkedLibraries:Array<String>;
   var isSimulator:Bool;

   var no3xResoltion:Bool;
   var parentProject:NMEProject;
  

   public function new(inProject:NMEProject)
   {
      parentProject = inProject;
      super(inProject.makeWatchOSConfig());

      launchPid = 0;
      redirectTrace = false;

      for(asset in project.assets) 
         asset.resourceName = asset.targetPath = asset.flatName;

      isSimulator = project.hasDef("watchsimulator");
      project.haxeflags.push('-cpp $haxeDir/cpp');
      project.haxeflags.push("-D HXCPP_CPP11");
      project.addClassPath(getOutputDir());
   }

   override public function buildPackage():Void 
   {
      // Prevent re-entry
      Sys.putEnv("NME_ALREADY_BUILDING","BUILDING");
   }

   override public function getBinName() : String { return "watchos"; }
   override public function getAssetDir() { return getOutputDir() + "/Assets.xcassets"; }
   override public function getPlatformDir() : String { return "watchos"; }
   override public function getOutputDir() { return parentProject.app.binDir + "/ios/" + project.app.file + " Extension"; }


   override private function generateContext(context:Dynamic)
   {

      context.HAS_ICON = false;
      context.HAS_LAUNCH_IMAGE = false;
      context.OBJC_ARC = false;
      context.PROJECT_DIRECTORY = Sys.getCwd();
      context.APP_FILE = project.app.file;
      context.REDIRECT_TRACE = redirectTrace;
      context.IOS_3X_RESOLUTION = project.getBool("ios3xResolution",true);
      if (project.watchProject!=null)
         context.NME_WATCHOS = true;

      if (project.window.ui=="spritekit")
         context.NME_WATCH_SPRITEKIT = true;


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

      var config = project.iosConfig;

      context.frameworkSearchPaths = project.frameworkSearchPaths;

      context.MACROS = {};
      context.MACROS.appIcon = createAppIcon;
      context.PRERENDERED_ICON = config.prerenderedIcon;

      //updateIcon();
      //updateLaunchImage();
   }

   override public function trace()
   {
   }


   override public function runHaxe()
   {
      var args = project.debug ? ['$haxeDir/build.hxml',"-debug"] : ['$haxeDir/build.hxml'];

      runHaxeWithArgs(args.concat(["-D","static_link","-D", isSimulator?"watchsimulator":"watchos"]) );
   }

   function copyApplicationMain(end:String, arch:String)
   {
      var projectDirectory = getOutputDir();
      var file = haxeDir + "/cpp/libApplicationMain" + end;
      FileHelper.copyIfNewer(file, projectDirectory + "/lib/" + arch + "/libApplicationMain.a" );
   }


   override public function copyBinary():Void 
   {
      var dbg = project.debug ? "-debug" : "";

      if (isSimulator)
         copyApplicationMain(dbg + ".watchsimulator.a", "i386");
      else
         copyApplicationMain(dbg + ".watchos.a", "armv7k");
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


   override public function updateOutputDir():Void 
   {
      var nmeLib = new Haxelib("nme");

      var projectDirectory = getOutputDir();

      PathHelper.mkdir(targetDir);
   }

   override public function updateLibs()
   {
      var projectDirectory = getOutputDir();

      PathHelper.mkdir(projectDirectory + "/lib");

      var part = isSimulator ? "watchsimulator" : "watchos";
      var arch = isSimulator ? "i386" : "armv7k";
      var libExt = "." + part + ".a";

      var dbg = project.debug ? "-debug" : "";
      PathHelper.mkdir(projectDirectory + "/lib/" + part + dbg);

      for(ndll in project.ndlls) 
      {
         var releaseLib = ndll.find("watchos", "lib", libExt);
         var releaseDest = projectDirectory + "/lib/" + arch + "/lib" + ndll.name + ".a";

         if (!FileSystem.exists(releaseLib))
            Log.verbose("Skip non-existent library " + releaseLib );
         else
            FileHelper.copyIfNewer(releaseLib, releaseDest);
      }
   }


   override public function updateAssets()
   {
      var base = getAssetDir();
      PathHelper.mkdir(base);
      for(asset in project.assets) 
      {
         if (!asset.embed && asset.type==AssetType.IMAGE)
         {
            var imageset = base + "/" + asset.flatName + ".imageset";
            PathHelper.mkdir(imageset);
            var file = haxe.io.Path.withoutDirectory(asset.sourcePath);
            FileHelper.copyAssetIfNewer(asset, imageset+"/" + file);
            var contents = '{
  "images" : [
    {
      "idiom" : "universal",
      "filename" : "$file",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}';
             sys.io.File.saveContent( imageset+"/Contents.json", contents );
         }
      }
   }






}
