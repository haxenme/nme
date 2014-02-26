package platforms;

import sys.FileSystem;
import haxe.io.Path;

class Platform
{
   public static inline var ANDROID = "ANDROID";
   public static inline var FLASH = "FLASH";
   public static inline var IOS = "IOS";
   public static inline var IOSVIEW = "IOSVIEW";
   public static inline var LINUX = "LINUX";
   public static inline var MAC = "MAC";
   public static inline var WINDOWS = "WINDOWS";
   public static inline var ANDROIDVIEW = "ANDROIDVIEW";


   public static inline var TYPE_WEB = "WEB";
   public static inline var TYPE_DESKTOP = "DESKTOP";
   public static inline var TYPE_MOBILE = "MOBILE";

   public var platform(get,null):String;

   var project:NMEProject;
   var targetDir:String;
   var haxeDir:String;
   var useNeko:Bool;
   var is64:Bool;
   var context:Dynamic;

   public function new(inProject:NMEProject)
   {
      project = inProject;
      useNeko = project.targetFlags.exists("neko");
      is64 = false;
      if (useNeko)
         is64 = nme.Lib.bits == 64;
      else
         for(architecture in project.architectures) 
            if (architecture == Architecture.X64) 
               is64 = true;
      targetDir = project.app.binDir + "/" + getPlatformDir();
      haxeDir = targetDir + "/haxe";
   }

   public function init()
   {
      context = project.getContext(haxeDir);
      generateContext(context);
   }

   function generateContext(context:Dynamic) : Void { }
   public function getPlatformDir() : String { return null; }
   public function get_platform() : String { return null; }
   public function getBinName() : String { return ""; }
   public function getNdllExt() : String { return ".ndll"; }
   public function getLibExt() : String { return ".a"; }
   public function getNdllPrefix() : String { return ""; }
   public function getOutputExtra() : String { return ""; }
   public function getOutputDir() { return targetDir + "/" + project.app.file; }
   public function getAssetDir() { return getOutputDir(); }
   public function getExeDir() { return getOutputDir(); }
   public function getLibDir() { return getExeDir(); }
   public function getNativeDllExt() { return ".so"; }
   public function getArchSuffix() { return ""; }
   public function postBuild() { }


   public function hasArch(inArch:Architecture)
   {
      return ArrayHelper.containsValue(project.architectures, inArch);
   }

   public function runHaxe()
   {
      var args = project.debug ? ["build.hxml","-debug"] : ["build.hxml"];

      ProcessHelper.runCommand(haxeDir, "haxe", args);
   }

   public function copyBinary() { }
   public function clean()
   {
      if (FileSystem.exists(targetDir)) 
         PathHelper.removeDirectory(targetDir);
   }

   public function display() { }
   public function install() { }
   public function prepareTest() { }
   public function run(arguments:Array<String>) { }
   public function trace() { }
   public function uninstall() { }

   public function copyTemplateDir(from:String, to:String, warnIfNotFound = true) : Bool
   {
      return FileHelper.recursiveCopyTemplate(project.templatePaths, from, to, context, true, warnIfNotFound);
   }
   public function copyTemplate(from:String, to:String)
   {
      FileHelper.copyFileTemplate(project.templatePaths, from, to, context);
   }

   public function updateBuildDir()
   {
      PathHelper.mkdir(targetDir);
      PathHelper.mkdir(haxeDir);

      copyTemplateDir("haxe", haxeDir );
   }

   public function updateOutputDir()
   {
      var output = getOutputDir();
      PathHelper.mkdir(output);
   }

   public function buildPackage() { }


   public function updateAssets()
   {
      var base = getAssetDir();
      PathHelper.mkdir(base);
      for(asset in project.assets) 
      {
         if (!asset.embed)
         {
            PathHelper.mkdir(Path.directory(base + "/" + asset.targetPath));
            FileHelper.copyAssetIfNewer(asset, base + "/" + asset.targetPath);
         }
      }
   }

   public function updateLibArch(libDir:String, archSuffix:String)
   {
      PathHelper.mkdir(libDir);

      var binName = getBinName();
      var pref = getNdllPrefix();
      for(ndll in project.ndlls) 
      {
         var ext = getNdllExt();
         var dir = "/ndll/" + binName + "/";
         var srcProject = PathHelper.getHaxelib(ndll.haxelib);

         var src = srcProject + "/ndll/" + binName + "/" + pref + ndll.name + archSuffix + ext;

         if (ndll.isStatic && !useNeko)
         {
            continue;
            // var ext = getLibExt();
            // src = srcProject + "/lib/" + binName + "/lib" + ndll.name + archSuffix + ext;
         }
         else if (ndll.haxelib.name=="hxcpp")
         {
            if (useNeko)
               src = NekoHelper.getNekoDir() + "/" + pref + ndll.name + archSuffix + ext;
            else
            {
               ext = getNativeDllExt();
               src = srcProject + "/bin/" + binName + "/" + pref + ndll.name + archSuffix + ext;
            }
         }


         if (FileSystem.exists(src)) 
         {
            var dest = libDir + "/" + pref + ndll.name + ext;

            LogHelper.info("", " - Copying library file: " + src + " -> " + dest);
            FileHelper.copyIfNewer(src, dest);
         }
         else
         {
            LogHelper.error("Source path \"" + src + "\" does not exist");
         }
      }
   }

   public function updateLibs()
   {
      updateLibArch( getLibDir(), getArchSuffix() );
   }

   public function updateExtra()
   {
      var extra = getOutputExtra();
      if (extra!="")
      {
         var output = getOutputDir();

         copyTemplateDir(extra,  output);
      }
   }
}
