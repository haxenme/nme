package platforms;

import sys.FileSystem;
import haxe.io.Path;
import sys.net.Host;
import sys.net.Socket;

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
   public static inline var CPPIA = "CPPIA";


   public static inline var TYPE_WEB = "WEB";
   public static inline var TYPE_DESKTOP = "DESKTOP";
   public static inline var TYPE_MOBILE = "MOBILE";
   public static inline var TYPE_SCRIPT = "SCRIPT";

   public var platform(get,null):String;

   var project:NMEProject;
   var targetDir:String;
   var haxeDir:String;
   var useNeko:Bool;
   var is64:Bool;
   var context:Dynamic;
   var outputFiles:Array<String>;
   var adbName:String;
   var adbFlags:Array<String>;


   public function new(inProject:NMEProject)
   {
      project = inProject;
      outputFiles = [];
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

   public function addOutput(inFile:String) : Void
   {
      var base = getOutputDir() + "/";
      var l = base.length;
     if (inFile.substr(0,l)==base)
         outputFiles.push( inFile.substr(l) );
      else if (inFile.substr(inFile.length-8)!=".pbxproj" &&
            inFile.indexOf("android-view")<0 && inFile.indexOf("ios-view")<0 )
      {
         Log.warn( inFile + " does not appear to be under " + base );
      }
 
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
   public function getHaxeTemplateDir() { return "haxe"; }
   public function getNativeDllExt() { return ".so"; }
   public function getArchSuffix() { return ""; }
   public function postBuild() { }



   public function setupAdb()
   {
      if (adbName!=null)
         return;

      adbName = "adb";
      if (PlatformHelper.hostPlatform == Platform.WINDOWS) 
         adbName += ".exe";

      var test = project.environment.get("ANDROID_SDK") + "/tools/" + adbName;
      if (FileSystem.exists(test))
         adbName = test;
      else
      {
         var test = project.environment.get("ANDROID_SDK") + "/platform-tools/" + adbName;
         if (FileSystem.exists(test))
            adbName = test;
         // Hmm - use relative path and hope it works
      }

      adbFlags = [];
      if (project.targetFlags.exists("device"))
         adbFlags = [ "-s", project.targetFlags.get("device") ];
      else if (project.targetFlags.exists("androidsim") || project.targetFlags.exists("e"))
         adbFlags = [ "-e" ];
      else
         adbFlags = [ "-d" ] ;
   }


   public function hasArch(inArch:Architecture)
   {
      return ArrayHelper.containsValue(project.architectures, inArch);
   }

   public function runHaxe()
   {
      var args = [haxeDir + "/build.hxml"];
      if (project.debug)
         args.push("-debug");

      ProcessHelper.runCommand("", "haxe", args);
   }

   public function copyBinary() { }
   public function tidy()
   {
      var dir =  getOutputDir();
      Log.verbose(" clean " + dir);
      if (FileSystem.exists(dir))
         PathHelper.removeDirectory(dir);
   }

   public function clean()
   {
      Log.verbose(" clean " + targetDir);
      if (FileSystem.exists(targetDir)) 
         PathHelper.removeDirectory(haxeDir);
   }

   public function display() { }

   public function install() { }

   public function getResult(socket:Socket) : String
   {
      var fromSocket = socket.input;
      var len = fromSocket.readInt32();
      return fromSocket.readString(len);
   }

   public function bye(socket:Socket)
   {
      var toSocket = socket.output;
      var message = "bye";
      toSocket.writeInt32(message.length);
      toSocket.writeString(message);
   }
   public function sendRun(socket:Socket, inAppName:String) : Bool
   {
      var toSocket = socket.output;
      var message = "run";
      toSocket.writeInt32(message.length);
      toSocket.writeString(message);

      toSocket.writeInt32(inAppName.length);
      toSocket.writeString(inAppName);

      var result = getResult(socket);
      if (result=="ok")
         return true;
      if (result=="restart")
         return false;

      Log.error("Unknown run result:" + result);
      return false;
   }

   public function transfer(socket:Socket, from:String, to:String)
   {
      var toSocket = socket.output;
      var file = sys.io.File.getBytes(from);
      if (file==null)
         Log.error("Could not open " + from);
      Log.verbose("Sending " + to + "(" + file.length + ")");
      var message = "put";
      toSocket.writeInt32(message.length);
      toSocket.writeString(message);

      toSocket.writeInt32(to.length);
      toSocket.writeString(to);

      toSocket.writeInt32(file.length);
      toSocket.write(file);

      var result = getResult(socket);
      if (result!="ok")
         Log.error("Error sending " + from + " : " + result);
      Log.verbose(result);
   }

   public function deploy(inAndRun:Bool) : Bool
   {
      var deploy = project.getDef("deploy");
      if (deploy!=null)
      {
         var from = getOutputDir();

         if (deploy.substr(0,4)=="adb:")
         {
            setupAdb();
            var to = deploy.substr(4) + "/" + project.app.file;
            trace(outputFiles);
            for(file in outputFiles)
            {
               Log.verbose("adb push " + file);
               ProcessHelper.runCommand(from,adbName, adbFlags.concat(["push", file, to+"/"+file]) );
            }
         }
         else if (deploy.substr(0,4)=="net:")
         {
            var host = new Host(deploy.substr(4));
            Log.verbose("Connect to host " + host);
            var socket = new Socket();
            try
            {
               socket.connect(host, 0xacad);

               var to = project.app.file;
               for(file in outputFiles)
                  transfer(socket, from+"/"+file, to+"/"+file);

               var ran = inAndRun && sendRun(socket, project.app.file);
               if (!ran || !inAndRun)
                  bye(socket);
               socket.close();
               return inAndRun;
            }
            catch(e:Dynamic)
            {
               Log.error("Could not connect to " + deploy + " : " + e );
            }
         }
         else
         {
            var to = deploy + "/" + project.app.file;
            for(file in outputFiles)
            {
               Log.verbose("copy " + file);
               FileHelper.copyFile(from+"/"+file,to+"/"+file);
            }

         }
      }
      return false;
   }

   public function prepareTest() { }
   public function run(arguments:Array<String>) { }
   public function trace() { }
   public function uninstall() { }

   public function copyTemplateDir(from:String, to:String, warnIfNotFound = true, ?inForOutput=true) : Bool
   {
      return FileHelper.recursiveCopyTemplate(project.templatePaths, from, to, context, true, warnIfNotFound, 
          inForOutput ? addOutput : null );
   }
   public function copyTemplate(from:String, to:String)
   {
      FileHelper.copyFileTemplate(project.templatePaths, from, to, context, addOutput);
   }

   public function updateBuildDir()
   {
      PathHelper.mkdir(targetDir);
      PathHelper.mkdir(haxeDir);

      copyTemplateDir( getHaxeTemplateDir(), haxeDir, true, false );
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
         var target = catPaths(base, asset.targetPath );
         if (!asset.embed)
         {
            PathHelper.mkdir(Path.directory(target));
            addOutput(target);
            FileHelper.copyAssetIfNewer(asset, target);
         }
      }
   }

   public function catPaths(inBase:String, inExtra:String)
   {
      return PathHelper.combine(inBase,inExtra);
   }

   public function updateLibArch(libDir:String, archSuffix:String)
   {
      var binName = getBinName();
      if (binName==null)
         return;

      PathHelper.mkdir(libDir);

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
            addOutput(dest);

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

         copyTemplateDir(extra,  output );
      }
   }
}
