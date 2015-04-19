package platforms;

import sys.FileSystem;
import sys.io.File;
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
   public static inline var EMSCRIPTEN = "EMSCRIPTEN";


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
   var manifest:Dynamic;
   var md5s:Map<String,String>;
   var remoteMd5s:Map<String,String>;
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

   public function wantLldb() : Bool
   {
      return project.hasDef("lldb");
   }

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

   public function createInstaller() { }

   public function createManifestHeader(?inBody:haxe.io.Bytes, includeIcon=false)
   {
      var header:Dynamic = {};
      header.name = project.app.title;
      header.developer = project.app.company;
      header.id = project.app.packageName;
      header.engines = new Array<Dynamic>();
      for(engine in project.engines.keys())
         header.engines.push( {name:engine, version:project.engines.get(engine)} );

      if (includeIcon)
      {
         try
         {
            var icon = IconHelper.getSvgIcon(project.icons);
            if (icon!=null)
               header.svgIcon = File.getContent(icon);
            else
            {
               var iconFile = getOutputDir() + "/icon.png";
               header.bmpIcon = haxe.crypto.Base64.encode(File.getBytes(icon));
            }
         }
      }
      return header;
   }

   public function addManifest()
   {
      try
      {
         if (manifest==null)
         {
            manifest = {};
            manifest.header = createManifestHeader();
            md5s = new Map<String,String>();

            var headerMd5s:Dynamic = {};

            var from = getOutputDir();
            var lines = new Array<String>();
            for(filename in outputFiles)
            {
                var file = sys.io.File.getBytes(from+"/"+filename);
                var md5 = haxe.crypto.Md5.make(file).toHex();
                md5s.set(filename,md5);
                Reflect.setField(headerMd5s,filename,md5);
            }
            manifest.md5s = headerMd5s;
            var manifestName = getOutputDir() + "/manifest.json";
            sys.io.File.saveContent(manifestName, haxe.Json.stringify(manifest) );
            outputFiles.push("manifest.json");
            Log.verbose("Created manifest : " + manifestName);
         }
      }
      catch(e:Dynamic)
      {
         Log.error("Error creating manifest " + e);
      }
   }

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

   public function pullFile(socket:Socket, from:String) : haxe.io.Bytes
   {
      var toSocket = socket.output;
      var message = "pull";
      toSocket.writeInt32(message.length);
      toSocket.writeString(message);

      toSocket.writeInt32(from.length);
      toSocket.writeString(from);


      var fromSocket = socket.input;
      var len = fromSocket.readInt32();
      if (len==-1)
         return null;

      var bytes = haxe.io.Bytes.alloc(len);
      fromSocket.readBytes(bytes,0,len);
      Log.verbose("Pulled " + from + " bytes: " + bytes.length );
      return bytes;
   }

   public function parseMd5s(inFile:String)
   {
      var result = new Map<String, String>();
      try
      {
         var json = haxe.Json.parse(inFile);
         if (json!=null)
         {
            var md5s = json.md5s;
            if (md5s!=null)
               for(key in Reflect.fields(md5s))
                  result.set(key, Reflect.field(md5s,key));
            else
               Log.warn("Missing md5s in manifest");
         }
      }
      catch(e:Dynamic)
      {
         Log.warn("Invalid Json format " + e);
      }
      return result;
   }

   public function deploy(inAndRun:Bool) : Bool
   {
      addManifest();

      var deploy = project.getDef("deploy");
      Log.verbose("Deployment target " + deploy );
      if (deploy!=null)
      {
         var from = getOutputDir();

         if (deploy.substr(0,4)=="adb:")
         {
            setupAdb();
            var to = deploy.substr(4) + "/" + project.app.packageName;
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

               var to = project.app.packageName;

               var manifest = project.hasDef("forcedeploy") ? null :  pullFile(socket, to+"/manifest.json");
               if (manifest!=null)
                  remoteMd5s = parseMd5s(manifest.toString());

               for(file in outputFiles)
               {
                  var remote = remoteMd5s==null ? null : remoteMd5s.get(file);
                  if (remote==null || remote!=md5s.get(file))
                     transfer(socket, from+"/"+file, to+"/"+file);
                  else
                     Log.verbose("Already deployed " + file);
               }

               var ran = inAndRun && sendRun(socket, project.app.packageName);
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
      for(path in project.templateCopies)
         FileHelper.copyFile(path.from, getOutputDir() + "/" + path.to );
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
         else if (ndll.allowMissing)
         {
            LogHelper.verbose("Source path \"" + src + "\" does not exist - ignoring");
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
