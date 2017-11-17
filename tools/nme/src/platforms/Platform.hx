package platforms;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import sys.net.Host;
import sys.net.Socket;
import nme.AlphaMode;
import nme.script.NmeItem;
import haxe.zip.Entry;
import haxe.zip.Writer;
using StringTools;

class Platform
{
   public static inline var ANDROID = "ANDROID";
   public static inline var FLASH = "FLASH";
   public static inline var IOS = "IOS";
   public static inline var IOSVIEW = "IOSVIEW";
   public static inline var LINUX = "LINUX";
   public static inline var MAC = "MAC";
   public static inline var WINDOWS = "WINDOWS";
   public static inline var WINRT = "WINRT";
   public static inline var ANDROIDVIEW = "ANDROIDVIEW";
   public static inline var CPPIA = "CPPIA";
   public static inline var RPI = "RPI";
   public static inline var EMSCRIPTEN = "EMSCRIPTEN";
   public static inline var HTML5 = "HTML5";
   public static inline var JS = "JS";
   public static inline var WATCH = "WATCH";
   public static inline var JSPRIME = "JSPRIME"; // Alias for HTML5


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
   var deployDir:String;


   public function new(inProject:NMEProject)
   {
      project = inProject;
      outputFiles = [];
      useNeko = project.targetFlags.exists("neko");
      is64 = false;
      if (useNeko)
         is64 = nme.Lib.bits == 64;
      else
      {
         if (inProject.hasDef("HXCPP_M32"))
         {
         }
         else if (inProject.hasDef("HXCPP_M64"))
         {
            is64 = true;
         }
         else
            for(architecture in project.architectures) 
               if (architecture == Architecture.X64) 
                  is64 = true;
      }
      targetDir = project.app.binDir + "/" + getPlatformDir();
      haxeDir = targetDir + "/haxe";
   }

   public function addOutput(inFile:String) : Void
   {
      var base = getOutputDir() + "/";
      var l = base.length;
     if (inFile.substr(0,l)==base)
         outputFiles.push( inFile.substr(l) );
      else if (inFile.substr(inFile.length-8)!=".pbxproj" && inFile.indexOf("ios")<0 &&
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

   public function runHaxeWithArgs(args:Array<String>)
   {
      var haxeRoot = project.getDef("HAXE_ROOT");
      if (haxeRoot!=null)
      {
         var haxe = haxeRoot + "/haxe";
         if (PlatformHelper.hostPlatform == Platform.WINDOWS) 
             haxe += ".exe";
         var oldStdPath = Sys.getEnv("HAXE_STD_PATH");
         Sys.putEnv("HAXE_STD_PATH", haxeRoot + "/std");

         Log.verbose("Run: " + haxe + " " + args.join(" "));
         ProcessHelper.runCommand("", haxe, args);

         if (oldStdPath!=null)
            Sys.putEnv("HAXE_STD_PATH", oldStdPath);
      }
      else
      {
         Log.verbose("Run: haxe " + args.join(" "));
         ProcessHelper.runCommand("", "haxe", args);
      }
   }

   public function runHaxe()
   {
      var args = [haxeDir + "/build.hxml"];
      if (project.debug)
         args.push("-debug");

      runHaxeWithArgs(args);
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

   public function createManifestHeader()
   {
      var header:Dynamic = {};
      header.name = project.app.title;
      header.developer = project.app.company;
      header.id = project.app.packageName;
      header.version = 1;
      header.nme = nme.Version.name;

      if ( project.icons!=null && project.icons.length>0)
      {
         try
         {
            var icon = IconHelper.getSvgIcon(project.icons);
            if (icon!=null)
               header.svgIcon = File.getContent(icon);
            else
            {
               IconHelper.createIcon(project.icons, 128, 128, getOutputDir() + "/icon.png", addOutput);
               var iconFile = getOutputDir() + "/icon.png";
               header.bmpIcon = haxe.crypto.Base64.encode(File.getBytes(icon));
            }
         }
         catch(e:Dynamic)
         {
            Log.error("Error creating icon from " + project.icons + ":" + e);
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
            manifest = createManifestHeader();
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

   public function getDeploymentName(extension:String)
   {
      var version = project.app.version;
      var parts = version.split(".");
      if (parts.length==3)
      {
         version = "_" + parts.shift();
         for(p in parts)
         {
            var i = Std.parseInt(p);
            if (i<=0)
               version += "000";
            else if (i<10)
               version += "00" + i;
            else if (i<100)
               version += "0" + i;
            else
               version +=  i;
         }
      }
      else if (version!="")
         version = "_" + version;
        
      return project.app.file + version + extension;
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
      var target = CommandLineTools.parseDeploy(project.getDef("deploy"),false,false);
      if (target!=null)
      {
         Log.verbose("Deployment target " + target );

         var protocol = target.protocol;
         var name =target.name;
         var from = getOutputDir();

         if (protocol=="adb")
         {
            setupAdb();
            var to = name + "/" + project.app.packageName;
            for(file in outputFiles)
            {
               Log.verbose("adb push " + file);
               ProcessHelper.runCommand(from,adbName, adbFlags.concat(["push", file, to+"/"+file]) );
            }
         }
         else if (protocol=="script")
         {
            try
            {
               var socket = new Socket();
               var parts = name.split("@");
               var hostName = parts.pop();
               var host = new Host(hostName);
               var password = parts.join("@");

               Log.verbose("Connect to host " + hostName);

               socket.connect(host, 0xacad);
               if (password!="")
               {
                  var len = socket.input.readInt32();
                  var hash = socket.input.readString(len);
                  var response = haxe.crypto.Md5.encode( password + hash );
                  socket.output.writeInt32(response.length);
                  socket.output.writeString(response);
               }

               if (project.expandCppia())
               {
                  var to = project.app.packageName;

                  // todo - timestamp
                  var forced = project.hasDef("forcedeploy");
                  var stampFile = haxeDir + "/" + host + ".up";
                  var timestamp:Float = 0;
                  if (!forced)
                  {
                     if (!FileSystem.exists(stampFile))
                        forced = true;
                     else
                     {
                        var info = FileSystem.stat(stampFile);
                        var mtime = info.atime;
                        if (mtime==null)
                           forced = true;
                        else
                           timestamp = mtime.getTime();
                     }
                  }
                  trace(outputFiles);
                  for(file in outputFiles)
                  {
                     var remote = remoteMd5s==null ? null : remoteMd5s.get(file);
                     if (forced || FileSystem.stat(from+"/"+file).mtime.getTime()>=timestamp)
                        transfer(socket, from+"/"+file, to+"/"+file);
                     else
                        Log.verbose("Already deployed " + file);
                  }
                  File.saveContent(stampFile,Std.string(timestamp));

                  var ran = inAndRun && sendRun(socket, project.app.packageName);
                  if (!ran || !inAndRun)
                     bye(socket);
               }
               else
               {
                  var src = getOutputDir() + "/" + getNmeFilename();
                  var to = project.app.packageName+".nme";
                  transfer(socket, src, to);
                  var ran = inAndRun && sendRun(socket, to);
                  if (!ran || !inAndRun)
                     bye(socket);
               }
               socket.close();
               return inAndRun;
            }
            catch(e:Dynamic)
            {
               Log.error("Could not connect to " + name + " : " + e );
            }
         }
         else if (protocol=="nme")
         {
            var filename = getOutputDir() + "/" + project.app.file + ".nme";
            if (!FileSystem.exists(filename))
               Log.error('Could not find  $filename to deploy');
            var path = name;
            if (!path.endsWith(".nme"))
               path += "/" +  project.app.file + ".nme";
            Log.verbose("deploy nme " + path);
            FileHelper.copyFile(filename, path);
         }
         else if (protocol=="dir" || protocol=="bindir")
         {
            var arch = "";
            if (protocol=="bindir")
            {
               var bin = getBinName();
               // Cross compile
               if (bin=="RPi")
                  arch = "/RPi/" + project.app.file;
               else if (bin=="Linux" || bin=="Linux64")
                  arch = "/Linux/" + project.app.file;
               else switch(PlatformHelper.hostPlatform)
               {
                  case WINDOWS: arch="/Windows/" + project.app.file;
                  case MAC: arch="/Mac/" + project.app.file + ".app";
                  case LINUX: arch="/Linux/" + project.app.file;
                  default:Log.error("Unkown host platform for bindir, " + PlatformHelper.hostPlatform);
               }
            }

            deployDir = name + arch;
            Log.verbose("Deploy to " + deployDir);
            for(file in outputFiles)
            {
               Log.verbose("copy " + file);
               FileHelper.copyFile(from+"/"+file,deployDir+"/"+file);
            }
         }
         else if (protocol=="zip")
         {
             var entries:List<Entry> = new List();
             var from = getOutputDir();
             var to = project.app.file + "/";
             for(file in outputFiles)
             {
                Log.verbose('  zip $to$file');
                try {
                   var bytes = sys.io.File.getBytes(from+"/"+file);
                   var zipped = haxe.zip.Compress.run(bytes,9);
                   zipped = zipped.sub(2,zipped.length-6);
                   if (zipped.length > bytes.length*0.9)
                      zipped = null;
                   entries.add( {
                      fileName : to + file,
                      fileSize : bytes.length,
                      fileTime : Date.now(),
                      compressed : zipped!=null,
                      dataSize : zipped==null ? 0 : zipped.length,
                      data : zipped==null ? bytes : zipped,
                      crc32 : haxe.crypto.Crc32.make(bytes),
                      extraFields : new List()
                   } );
                }
                catch(e:Dynamic)
                {
                   Log.error('Could not include $file in zip file');
                }
             }

             if (name=="" || name==null)
                name = getDeploymentName(".zip");

             var wrote = 0;
             try {
                var bytesOutput = new haxe.io.BytesOutput();
                var writer = new Writer(bytesOutput);
                writer.write(entries);
                // Grab the zipped file from the output stream
                var zipfileBytes = bytesOutput.getBytes();
                wrote = zipfileBytes.length;
                // Save the zipped file to disc
                var file = File.write(name, true);
                file.write(zipfileBytes);
                file.close();
             }
             catch(e:Dynamic)
             {
                Log.error('Could not save zip file $name');
             }
             Log.info('Wrote zip $name, $wrote bytes');
         }
         else
            Log.error("Unknown deployment protocol, use: 'script:', 'adb:' or 'dir:'");
      }
      return false;
   }

   public function prepareTest() { }
   public function run(arguments:Array<String>) { }
   public function trace() { }
   public function uninstall() { }

   public function copyTemplateDir(from:String, to:String, warnIfNotFound = true, ?inForOutput=true, ?inFilter:String->Bool) : Bool
   {
      return FileHelper.recursiveCopyTemplate(project.templatePaths, from, to, context, true, warnIfNotFound, 
          inForOutput ? addOutput : null, inFilter );
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
      var convertDir = project.app.binDir + "/converted";
      for(asset in project.assets) 
      {
         var target = catPaths(base, asset.targetPath );
         if (!asset.embed)
         {
            PathHelper.mkdir(Path.directory(target));
            addOutput(target);
            asset.cleanConversion(convertDir,target);
            FileHelper.copyAssetIfNewer(asset, target);
         }
      }
   }

   public function catPaths(inBase:String, inExtra:String)
   {
      return PathHelper.combine(inBase,inExtra);
   }

   public function remapName(dir:String,filename:String)
   {
      return dir + "/" + filename;
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
         var srcProject = ndll.path;

         var src = srcProject + "/ndll/" + binName + "/" + pref + ndll.name + archSuffix + ext;

         if (ndll.noCopy || (ndll.isStatic && !useNeko))
         {
            continue;
            // var ext = getLibExt();
            // src = srcProject + "/lib/" + binName + "/lib" + ndll.name + archSuffix + ext;
         }
         else if (ndll.isHxcppLib())
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
            var dest = remapName( libDir,  pref + ndll.name + ext );
            addOutput(dest);

            LogHelper.info("", " - Copying library file: " + src + " -> " + dest);
            FileHelper.copyIfNewer(src, dest);

            src+=".mem";
            if (FileSystem.exists(src)) 
            {
               var dest = dest + ".mem";
               addOutput(dest);

               LogHelper.info("", " - Copying library mem file: " + src + " -> " + dest);
               FileHelper.copyIfNewer(src, dest);
            }
         }
         else
         {
            LogHelper.error("Library source path \"" + src + "\" does not exist +(" + ndll + ")");
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


   public function getNmeFilename()
   {
      return project.app.file + ".nme";
   }

   public function createNmeFile()
   {
      PathHelper.mkdir(getOutputDir());

      var filename = getOutputDir() + "/" + getNmeFilename();

      var outfile = sys.io.File.write(filename,true);
      outfile.bigEndian = false;
      outfile.writeString("NME$");

      var header = haxe.Json.stringify( createManifestHeader() );
      outfile.writeInt32(header.length);
      outfile.writeString(header);

      var data = new Array<haxe.io.Bytes>();
      var offset = 0;

      var index = new Array<NmeItem>();

      for(s in ["cppiaScript", "jsScript" ])
      {
         var script = project.getDef(s);
         if (script!=null)
         {
            var bytes = File.getBytes(script);
            data.push(bytes);
            var item = new NmeItem();
            item.offset = offset;
            item.length = bytes.length;
            item.type = "TEXT";
            item.id = s;
            index.push(item);
            offset += item.length;
         }
      }
 
      var base = getOutputDir();
      for(asset in project.assets)
      {
         var bytes = File.getBytes( asset.sourcePath);
         data.push(bytes);
         var item = new NmeItem();
         item.offset = offset;
         item.length = bytes.length;
         item.type = Std.string(asset.type);
         item.id = asset.id;
         if (asset.type==IMAGE)
            item.alphaMode = Std.string(asset.alphaMode);
         index.push(item);
         offset += item.length;
      }
 
      var indexData = haxe.Json.stringify(index);
      outfile.writeInt32(indexData.length);
      outfile.writeString(indexData);

      for(blob in data)
         outfile.writeBytes(blob,0,blob.length);

      outfile.close();

      Log.verbose("Wrote " + filename);
   }
}
