package;

import std.RealSys;
import std.SysProxy;
import haxe.io.Path;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;
import platforms.Platform;
import nme.system.System;
import nme.Loader;
import nme.net.SharedObject;
import nme.script.Client;
import NMEProject;
import nme.AlphaMode;

using StringTools;



class Fs
{
   public static function getDocs() return nme.filesystem.File.documentsDirectory.nativePath;
   public static function getDesktop() return nme.filesystem.File.desktopDirectory.nativePath;
}

class CommandLineTools 
{
   public static var nme(default,null):String;
   public static var home:String;
   public static var sys:SysProxy;
   public static var gradle:Bool = false;
   public static var quick:Bool = false;
   public static var fat:Bool = false;
   public static var browser:String = null;

   static var toolkit:Bool = true;
   static var haxeVer:String = null;
   static var additionalArguments:Array<String>;
   static var command:String;
   static var assumedTest:Bool = false;
   static var debug:Bool;
   static var forceFlag:Bool = false;
   static var staticFlag:Bool = false;
   static var sampleInDir:String = "";
   static var words:Array<String>;
   static var traceEnabled:Null<Bool>;
   static var host = PlatformHelper.hostPlatform;
   static var nmeVersion:String;
   static var binDirOverride:String = "";
   static var store:SharedObject;
   static var storeData:Dynamic;
   static var readHxcppConfig = false;


   static var allTargets = 
          [ "cpp", "neko", "ios", "iphone", "iphoneos", "iosview", "ios-view",
            "androidview", "android-view", "iphonesim", "android", "androidsim", "rpi",
            "windows", "mac", "linux", "flash", "cppia", "emscripten", "html5",
            "watchsimulator", "watchos", "jsprime", "winrt", "uwp" ];
   static var allCommands = 
          [ "help", "setup", "document", "generate", "create", "xcode", "clone", "demo",
             "installer", "copy-if-newer", "tidy", "set", "unset", "nocompile",
            "clean", "update", "build", "run", "rerun", "install", "uninstall", "trace", "test",
            "rebuild", "shell", "icon", "banner", "favicon", "serve", "listbrowsers" ];
   static var setNames =  [ "target", "bin", "command", "cppiaHost", "cppiaClassPath", "deploy", "developmentTeam" ];
   static var setNamesHelp =  [ "default when no target is specifiec", "alternate location for binary files", "default command to run", "executable for running cppia code", "additional class path when building cppia", "remote deployment host", "IOS development team id (10 character code)" ];
   static var quickSetNames =  [ "debug", "verbose" ];


   private static function buildProject(project:NMEProject) 
   {
      if (!loadProject(project,command=="script"))
         return;

      var platform:Platform = null;


      if (project.command=="nocompile")
         project.haxeflags.push("-D no-compilation");

      Log.verbose("Using target platform: " + project.target);
      Log.verbose("Using command : " + project.command);
      if (binDirOverride!="")
      {
         project.setBinDir(binDirOverride);
         Log.verbose("Overriding bin directory : " + project.app.binDir);
      }

      if (project.hasDef("fat"))
         fat=true;
      if (project.hasDef("quick"))
         quick=true;

      var buildFat = (command == "build" || command == "test") && !quick;

      switch(project.target) 
      {
         case Platform.ANDROID:
            platform = new platforms.AndroidPlatform(project);

         case Platform.IOSVIEW:
            platform = new platforms.IOSView(project);

         case Platform.ANDROIDVIEW:
            platform = new platforms.AndroidView(project);

         case Platform.IOS:
            platform = new platforms.IOSPlatform(project);

         case Platform.WINRT:
            platform = new platforms.WinrtPlatform(project);

         case Platform.WINDOWS:
            platform = new platforms.WindowsPlatform(project);

         case Platform.MAC:
            platform = new platforms.MacPlatform(project);

         case Platform.LINUX, Platform.RPI:
            platform = new platforms.LinuxPlatform(project);

         case Platform.FLASH:
            platform = new platforms.FlashPlatform(project);

         case Platform.CPPIA:
            var jsPlatform:platforms.JsPrimePlatform = null;
            if (fat && buildFat)
            {
               jsPlatform = new platforms.JsPrimePlatform(project);
               jsPlatform.runHaxe();
               jsPlatform.restoreState();
            }
            platform = new platforms.CppiaPlatform(project);
            if (jsPlatform!=null)
               jsPlatform.copyOutputTo(platform.getOutputDir());

         case Platform.EMSCRIPTEN:
            platform = new platforms.EmscriptenPlatform(project);

         case Platform.JS:
            platform = new platforms.JsPlatform(project);

         case Platform.WATCH:
            platform = new platforms.WatchPlatform(project);

         case Platform.JSPRIME, Platform.HTML5:
            var cppiaPlatform:platforms.CppiaPlatform = null;
            if (fat && buildFat)
            {
               cppiaPlatform = new platforms.CppiaPlatform(project);
               cppiaPlatform.runHaxe();
               cppiaPlatform.restoreState();
            }
            platform = new platforms.JsPrimePlatform(project);
            if (cppiaPlatform!=null)
               cppiaPlatform.copyOutputTo(platform.getOutputDir());
      }


      if (platform != null) 
      {
         platform.init();
         var haxed = false;

         var command = project.command.toLowerCase();

         if (command == "tidy" || project.targetFlags.exists("tidy") ||
             command == "clean" || project.targetFlags.exists("clean")) 
         {
            Log.verbose("\nRunning command: TIDY");
            platform.tidy();
         }

         if (command == "clean" || project.targetFlags.exists("clean")) 
         {
            Log.verbose("\nRunning command: CLEAN");
            platform.clean();
         }

         if (command == "uninstall" )
         {
            Log.verbose("\nRunning command: UNINSTALL");
            platform.uninstall();
         }

         if (command == "update" || command == "build" || command == "test" || command=="xcode" || command=="installer") 
         {
            Log.verbose("\nRunning command: UPDATE");
            platform.updateBuildDir();
            platform.updateOutputDir();
            if (!quick)
               platform.updateAssets();
            platform.updateLibs();
            platform.updateExtra();
         }

         if (command == "nocompile")
         {
            Log.verbose("\nRunning command: NOCOMPILE");
            platform.updateBuildDir();
            platform.runHaxe();
            haxed = true;
         }

         if (command == "build" || command == "test" || command=="xcode" || command=="installer") 
         {
            Log.verbose("\nRunning command: BUILD");
            platform.runHaxe();
            haxed = true;
            platform.copyBinary();
            if (command!="xcode")
            {
               platform.buildPackage();
               platform.postBuild();
            }
         }

         if (project.export!=null && haxed)
            export(project.export, project.exportFilter, project.exportSourceDir);

         if (command == "installer") 
         {
            platform.createInstaller();
         }

         if (command == "build" || command == "run" || command=="test" || command=="installer") 
         {
            if (platform.deploy(command!="build"))
               command = "build";
         }

         if (command == "install" || command == "run" || command == "test") 
         {
            Log.verbose("\nRunning command: INSTALL");
            platform.prepareTest();
            platform.install();
         }

         if (command == "run" || command == "rerun" || command == "test") 
         {
            Log.verbose("\nRunning command: RUN");
            platform.run(additionalArguments);
         }

         if (command == "test" || command == "trace") 
         {
            if (traceEnabled==null)
              traceEnabled = project.platformType == Platform.TYPE_MOBILE;
            if (traceEnabled || command == "trace") 
            {
               Log.verbose("\nRunning command: TRACE");
               platform.trace();
            }
         }
         Log.verbose("NME done.");
      }
   }

   static function showSampleHelp(inMode:String)
   {
      if (inMode=="demo")
         sys.println("nme demo [target] - build given sample [with given target]");
      else
         sys.println("nme clone [-in local-dir] - clone a project [into given directory]");

      sys.println('   nme $inMode directory - from given directory');
      sys.println('   nme $inMode nme-sample - $inMode nme sample');
      sys.println('   nme $inMode haxelib - list samples in given haxelib');
      sys.println('   nme $inMode haxelib:directory - sample from given haxelib directory');
      sys.println('   nme $inMode haxelib:sample-name - named sample from given haxelib');
      sys.println("");

      showSamples("NME",nme);
      //var joint = Log.mVerbose ? "\n" : ", ";
   }

   public static function unquote(x:String) : String
   {
      var result:String = "";
      while(true)
      {
         var slash = x.indexOf("\\");
         if (slash<0)
            return result + x;
         result += x.substr(0,slash);
         var next = x.substr(slash+1,1);
         if (next=="n")
            result += "\n";
         else if (next=="s")
            result += " ";
         else
            result += next;
         x = x.substr(slash+2);
      }
      return null;
   }


   static public function export(info:String, filter:String, sourceDir:String)
   {
         {
            try
            {
               var match = filter!="" && filter!=null ?  new EReg(filter,"") : null;
               var fileMatch = sourceDir!="" && sourceDir!=null ? ~/^file (\S*) ([^\r]*)/ : null;

               var content = File.getContent(info);
               var result = new Array<String>();
               var allMatched = true;
               var sourceCount = 0;
               var haxeStdPath = Sys.getEnv("HAXE_STD_PATH");
               var stdFile = "file " + haxeStdPath;
               for(line in content.split("\n"))
               {
                  if (match!=null && match.match(line))
                      result.push(line);
                  else
                     allMatched = false;

                  if (fileMatch!=null && !line.startsWith(stdFile) && fileMatch.match(line))
                  {
                     var dest = fileMatch.matched(1);
                     if (dest=="?")
                     {
                        // ignore odd hxcpp output
                     }
                     else if (PathHelper.isAbsolute(dest))
                     {
                        Log.verbose("Unusual absolute path destination " + dest);
                     }
                     else
                     {
                        var source = unquote(fileMatch.matched(2));
                        FileHelper.copyIfNewer(source, sourceDir + "/" + dest);
                        sourceCount++;
                     }
                  }
               }
               if (match!=null && !allMatched)
               {
                  File.saveBytes(info, haxe.io.Bytes.ofString(result.join("\n")));
                  Log.verbose("Cleaned export file " + info);
               }

               if (sourceCount>0)
               {
                  Log.verbose('Exported $sourceCount files to $sourceDir');
               }
            }
            catch(e:Dynamic)
            {
               Log.error('Error cleaning export file $info $e');
            }
         }
   }


   static function getSamples(dir:String)
   {
      var result = new Array<Sample>();

      var subDirs = ["/samples", ""];
      for(subDir in subDirs)
      {
         var test = dir + subDir;
         if (FileSystem.exists(test) && FileSystem.isDirectory(test))
         {
            if ( Sample.fromDir(test,result) )
               break;
         }
      }

      return result;
   }

   static function showSamples(name:String, dir:String)
   {
      var samples = getSamples(dir);

      var joint = "\n ";
      sys.println(name + " samples: " + joint + samples.join(joint) );
   }

   static function findSample(project:NMEProject,samples:Array<Sample>, name:String, target:String )
   {
      var nameLen = name.length;
      for(sample in samples)
      {
         if (name==sample.name ||
              (nameLen<sample.name.length && nameLen>=sample.short.length &&
                  name==sample.name.substr(0, nameLen) ) )
         {
            doSample(project,sample.path,target);
            return;
         }
      }
      // Once more, ignoring case...
      var lower = name.toLowerCase();
      for(sample in samples)
      {
         if (lower==sample.name ||
              (nameLen<sample.name.length && nameLen>=sample.short.length &&
                  lower==sample.name.substr(0, nameLen).toLowerCase() ) )
         {
            doSample(project,sample.path,target);
            return;
         }
      }


      var joint = "\n ";
      sys.println("Valid samples: " + joint + samples.join(joint) );
      Log.error("Could not find unique sample " + name);
   }


   static function doSample(project:NMEProject,dir:String,sampleTarget:String)
   {
      if (command=="demo")
      {
         if (sampleInDir=="")
         {
            if (binDirOverride!="")
               sampleInDir = binDirOverride;
            else
            {
               var path = new haxe.io.Path(dir);
               sampleInDir = path.file;
            }
         }

         if (!PathHelper.isAbsolute(sampleInDir))
            sampleInDir = PathHelper.normalise(Sys.getCwd()+ "/" + sampleInDir);

         Log.verbose("Building sample " + dir + " in " + sampleInDir); 
         var args = ["run","nme","test","-bin", sampleInDir ];
         if (Log.mVerbose)
            args.push("-v");
         if (debug)
            args.push("-debug");
         if (!toolkit)
            args.push("-notoolkit");
         if (gradle)
            args.push("-gradle");
         if (browser!=null)
         {
            args.push("-browser");
            args.push(browser);
         }

         if (project.hasDef("deploy"))
            args.push("deploy=" + project.getDef("deploy"));
         if (sampleTarget!="")
         {
            sys.println("Create demo " + dir + " for target " + sampleTarget);
            args.push(sampleTarget);
         }
         else
         {
            sys.println("Create demo " + dir + " using default target");
         }
         ProcessHelper.runCommand(dir, "haxelib", args);
      }
      else
      {
         if (sampleInDir=="")
         {
            var path = new haxe.io.Path(dir);
            sampleInDir = path.file;
         }

         sys.println("Clone " + dir + " in " + sampleInDir);
         FileHelper.recursiveCopy(dir, sampleInDir);

         var relocation = FileSystem.fullPath(dir);
         try
         {
           File.saveContent(sampleInDir+"/relocation.dir", relocation);
         }
         catch(e:Dynamic)
         {
            Log.error("Could not save relocation.dir:" + e);
         }

         if (sampleTarget!="")
         {
            var args = ["run","nme","test",sampleTarget ];
            if (Log.mVerbose)
               args.push("-v");
            if (debug)
               args.push("-debug");

            sys.println("Test " + sampleInDir + " using target " + sampleTarget);
            ProcessHelper.runCommand(sampleInDir, "haxelib", args);
         }
      }
   }

   static function processSample(project:NMEProject, inMode:String)
   {
      var target="";
      if (words.length>1 && isTarget(words[words.length-1]))
         target = words.pop();

      if (words.length==0)
        showSampleHelp(inMode);
      else
      {

        var arg = words[0];

        if (PathHelper.isAbsolute(arg) && FileSystem.exists(arg) && FileSystem.isDirectory(arg))
        {
           doSample(project, arg,target);
           return;
        }

        var parts = words.length>1 ? words : words[0].split(":");
        if (parts.length>1)
        {
           var name = Sample.projectOf(parts[0]);
           var path = PathHelper.getHaxelib(new Haxelib(name),true);
           if (path==null)
           {
              Log.error("Could not find haxelib " + name);
           }
           if (parts[1]=="")
              showSamples(name, path );
           else
           {
              var samples = getSamples(path);
              if (samples.length<1)
                 Log.error("Could not find samples in " + path);
              findSample(project,samples,parts[1],target);
           }
           return;
        }

        // maybe it is an nme sample or a haxelib ...
        var name = Sample.projectOf(words[0]);
        var path = PathHelper.getHaxelib(new Haxelib(name),true);
        if (path!=null)
            showSamples(name,path);
        else
        {
           var samples = getSamples(nme);
           if (samples.length<1)
               Log.error("Could not find nme samples");
           findSample(project,samples,words[0],target);
        }
     }
   }

   private static function createTemplate() 
   {
      if (words.length > 0) 
      {
         if (words[0] == "project") 
         {
            var id = [ "com", "example", "project" ];

            if (words.length > 1) 
            {
               var name = words[1];
               id = name.split(".");

               if (id.length < 3) 
               {
                  id = [ "com", "example" ].concat(id);
               }
            }

            var company = "Company Name";

            if (words.length > 2) 
            {
               company = words[2];
            }

            var context:Dynamic = { };

            var title = id[id.length - 1];
            title = title.substr(0, 1).toUpperCase() + title.substr(1);

            var packageName = id.join(".").toLowerCase();

            context.title = title;
            context.packageName = packageName;
            context.version = "1.0.0";
            context.company = company;
            context.file = StringTools.replace(title, " ", "");


            /*
            for(define in userDefines.keys()) 
            {
               Reflect.setField(context, define, userDefines.get(define));
            }
            */

            PathHelper.mkdir(title);
            FileHelper.recursiveCopyTemplate([ nme + "/templates/default" ], "project", title, context);

            if (FileSystem.exists(title + "/Project.hxproj")) 
            {
               FileSystem.rename(title + "/Project.hxproj", title + "/" + title + ".hxproj");
            }

         } else if (words[0] == "extension") 
         {
            var title = "Extension";

            if (words.length > 1) 
            {
               title = words[1];
            }

            var file = StringTools.replace(title, " ", "");
            var extension = StringTools.replace(file, "-", "_");
            var className = extension.substr(0, 1).toUpperCase() + extension.substr(1);

            var context:Dynamic = { };
            context.file = file;
            context.extension = extension;
            context.className = className;
            context.extensionLowerCase = extension.toLowerCase();
            context.extensionUpperCase = extension.toUpperCase();

            PathHelper.mkdir(title);
            FileHelper.recursiveCopyTemplate([ nme + "/templates" ], "extension", title, context);

            if (FileSystem.exists(title + "/Extension.hx")) 
            {
               FileSystem.rename(title + "/Extension.hx", title + "/" + className + ".hx");
            }

            if (FileSystem.exists(title + "/project/common/Extension.cpp")) 
            {
               FileSystem.rename(title + "/project/common/Extension.cpp", title + "/project/common/" + file + ".cpp");
            }

            if (FileSystem.exists(title + "/project/include/Extension.h")) 
            {
               FileSystem.rename(title + "/project/include/Extension.h", title + "/project/include/" + file + ".h");
            }
         }
         else
         {
            var sampleName = words[0];

            if (FileSystem.exists(nme + "/samples/" + sampleName)) 
            {
               PathHelper.mkdir(sampleName);
               FileHelper.recursiveCopy(nme + "/samples/" + sampleName, Sys.getCwd() + "/" + sampleName);
            }
            else
            {
               Log.error("Could not find sample project \"" + sampleName + "\"");
            }
         }
      }
      else
      {
         sys.println("You must specify 'project' or a sample name when using the 'create' command.");
         sys.println("");
         sys.println("Usage: ");
         sys.println("");
         sys.println(" nme create project \"com.package.name\" \"Company Name\"");
         sys.println(" nme create extension \"ExtensionName\"");
         sys.println(" nme create SampleName");
         sys.println("");
         sys.println("");
         sys.println("Available samples:");
         sys.println("");

         for(name in FileSystem.readDirectory(nme + "/samples")) 
         {
            if (FileSystem.isDirectory(nme + "/samples/" + name)) 
            {
               sys.println(" - " + name);
            }
         }
      }
   }

   private static function setup():Void 
   {
      if (PlatformHelper.hostPlatform==Platform.WINDOWS)
      {
         var haxePath:String = Sys.getEnv("HAXEPATH");
         if (haxePath==null || haxePath=="")
         {
            var nekoPath = System.exeName;
            var parts = nekoPath.split("\\");
            if (parts.length>3 && parts[parts.length-2]=="neko")
               haxePath = parts.slice(0,parts.length-2).join("\\") + "\\haxe";
            else
               haxePath = "C:\\HaxeToolkit\\haxe\\";
         }

         var target = haxePath + "\\nme.bat";
         var source = nme + "/tools/nme/bin/nme.bat";

         if (!forceFlag && FileSystem.exists(target))
         {
            sys.println("NME appears to be setup already.  Use '-f' to force reinstall");
         }
         else
         {
            try
            {
               File.copy(source,target);
               sys.println("Wrote " + target);
            }
            catch(e:Dynamic)
            {
              Log.error("Could not write " + target + " :" + e);
            }
         }
      }
      else
      {
         var source = nme + "/tools/nme/bin/nme.sh";
         var target = "/usr/local/bin/nme";

         if (!forceFlag && FileSystem.exists(target))
         {
            sys.println("NME appears to be setup already.  Use '-f' to force reinstall");
         }
         else
         {
            try
            {
               Sys.command("sudo", ["cp", source, target]);
               Sys.command("sudo", ["chmod", "755", target]);
            } catch (e:Dynamic) { }

            if (!FileSystem.exists(target))
               Log.error("NME setup failed - could not write " + target);
            else
               sys.println("Wrote " + target);
         }
      }
   }


   private static function document():Void 
   {
   }

   private static function displayHelp():Void 
   {
      displayInfo();

      sys.println("");
      sys.println(" Usage : nme help");
      sys.println(" Usage : nme [setup|clean|update|build|run|test] <project> (target) [options]");
      sys.println("");
      sys.println(" Commands : ");
      sys.println("");
      sys.println("  help : Show this information");
      sys.println("  tidy : Remove the target build directory if it exists");
      sys.println("  clean : Remove the target build directory and cpp obj files");
      sys.println("  update : Copy assets for the specified project/target");
      sys.println("  build : Compile and package for the specified project/target");
      sys.println("  run : Install and run for the specified project/target");
      sys.println("  test : Update, build and run in one command");
      sys.println("  clone : Copy an existing sample or project");
      sys.println("  demo :  Run an existing sample or project");
      sys.println("  create : Create a new project or extension using templates");
      sys.println("  setup : Create an alias for nme so you don't need to type 'haxelib run nme...'");
      sys.println("  rebuild : rebuild binaries from a build.xml file'");
      sys.println("  remake : rebuild nme tool and build nme project binaries for targets'");
      sys.println("  listbrowsers: show list of browsers that can be used with js targets");
      sys.println("  icon filename width height: generate project icon");
      sys.println("  banner filename width height: generate project banner");
      sys.println("  favicon filename: generate project favicon");
      sys.println("");
      sys.println(" Targets : ");
      sys.println("");
      sys.println("  cpp         : Create applications, for host system (linux,mac,windows)");
      sys.println("  cppia       : Create a cppia.nme bundle, and run with host (acadnme by default)");
      sys.println("  android     : Create Google Android applications");
      sys.println("  androidview : Create library files for inclusion in Google Android applications");
      sys.println("  androidsim  : android + simulator");
      sys.println("  iosview     : Create library files for inclusion in Apple iOS applications");
      sys.println("  flash       : Create SWF applications for Adobe Flash Player");
      sys.println("  jsprime     : Js application with c++ compiled runtime");
      sys.println("  neko        : Create application for rapid testing on host system");
      sys.println("  ios         : Create Apple iOS applications");
      sys.println("  rpi         : Create RaspberryPi applications");
      sys.println("  iphone      : ios + device debugging");
      sys.println("  iphonesim   : ios + simulator");
      sys.println("  watchos     : watch extension");
      sys.println("  watchsimulator : watch extension + simulator");
      sys.println("  winrt       : Create Universal Windows Platform applications");
      sys.println("");
      sys.println(" Options : ");
      sys.println("");
      sys.println("  -D : Specify a define to use when processing other commands");
      sys.println("  -debug : Use debug configuration instead of release");
      sys.println("  -megatrace : Add maximum debugging");
      sys.println("  -verbose : Print additional information(when available)");
      sys.println("  -f : force setup re-write");
      sys.println("  -vverbose : very berbose - includes haxe verbose mode");
      sys.println("  -tidy : remove ouput files");
      sys.println("  -clean : remove output files and c++ obj file store");
      sys.println("  -bin directory: put generated binaries in different directory");
      sys.println("  -browser id: which browser to launch with js targets");
      sys.println("  -nobrowser: do not launch browser js targets (just build + serve project)");
      sys.println("  [mac/linux/windows] -32 -64 : Compile for 32-bit or 64-bit instead of default");
      sys.println("  [android] -device=serialnumber : specify serial number");
      sys.println("  [ios] -simulator : Build/test for the device simulator");
      sys.println("  [ios] -simulator -ipad : Build/test for the iPad Simulator");
      sys.println("  (run|test) -args a0 a1 ... : Pass remaining arguments to executable");
   }

   private static function displayInfo(showHint:Bool = false, skipBanner:Bool = false):Void 
   {
      if (!skipBanner) // Does not show up so well in xcode
      {
         sys.println(" _____________");
         sys.println("|             |");
         sys.println("|__  _  __  __|");
         sys.println("|  \\| \\/  ||__|");
         sys.println("|\\  \\  \\ /||__|");
         sys.println("|_|\\_|\\/|_||__|");
         sys.println("|             |");
         sys.println("|_____________|");
         sys.println("");
      }
      sys.println("NME Command-Line Tools(" + nmeVersion + " @ '" + nme + "')");

      if (showHint) 
      {
         //if (!FileSystem.exits(
         sys.println("Use \"nme help\" for more commands");
      }
   }

   private static function findProjectFile(path:String):String 
   {
      if (FileSystem.exists(PathHelper.combine(path, "project.nmml"))) 
         return PathHelper.combine(path, "project.nmml");
      else if (FileSystem.exists(PathHelper.combine(path, "build.nmml"))) 
         return PathHelper.combine(path, "build.nmml");
      else if (FileSystem.exists(PathHelper.combine(path, "project.xml"))) 
         return PathHelper.combine(path, "project.xml");
      else if (FileSystem.exists(PathHelper.combine(path, "Project.xml"))) 
         return PathHelper.combine(path, "Project.xml");
      else
      {
         var files = FileSystem.readDirectory(path);
         var projs = [];
         var haxes = [];

         for(file in files) 
         {
            var path = PathHelper.combine(path, file);
            if (FileSystem.exists(path) && !FileSystem.isDirectory(path))
            {
               var ext = Path.extension(file);
               if (ext=="nmml" || ext=="xml")
                  projs.push(path);
               else if (ext=="hx")
                  haxes.push(path);
            }
         }

         if (projs.length==1)
            return projs[0];

         if (projs.length==0 && haxes.length==1)
            return haxes[0];
      }

      return "";
   }


   public static function runAcadnme(args:Array<String>, ?project:NMEProject)
   {
      //var host = project!=null ? project.getDef("CPPIA_HOST") : null;
      switch (host)
      {
         case Platform.WINDOWS:
            ProcessHelper.runCommand(nme + "/bin/Windows/Acadnme", "Acadnme.exe", args);

         case Platform.LINUX:
            ProcessHelper.runCommand("", "chmod", [ "u+x", nme + "/bin/Linux/Acadnme/Acadnme" ]);
            ProcessHelper.runCommand(nme + "/bin/Linux/Acadnme", "./Acadnme", args);

         case Platform.MAC:
            ProcessHelper.runCommand(nme + "/bin/Mac", "open", ["./Acadnme.app", "--args"].concat(args));

         default:
      }
   }


   private static function generate():Void 
   {
   }

   private static function getBuildNumber(project:NMEProject, increment:Bool = true):Void 
   {
      if (project.app.buildNumber == "1") 
      {
         var versionFile = PathHelper.combine(project.app.binDir, ".build");
         var version = 1;

         PathHelper.mkdir(project.app.binDir);

         if (FileSystem.exists(versionFile)) 
         {
            var previousVersion = Std.parseInt(File.getBytes(versionFile).toString());
            if (previousVersion != null) 
            {
               version = previousVersion;
               if (increment) 
                  version ++;
            }
         }

         project.app.buildNumber = Std.string(version);

         try 
         {
            var output = File.write(versionFile, false);
            output.writeString(Std.string(version));
            output.close();

         } catch(e:Dynamic) {}
      }
   }

   public static function getHXCPPConfig(project:NMEProject) : Void
   {
      var environment = Sys.environment();
      var config = "";

      if (environment.exists("HXCPP_CONFIG")) 
      {
         config = environment.get("HXCPP_CONFIG");
      }
      else
      {
         home = "";

         if (environment.exists("HOME")) 
            home = environment.get("HOME");
         else if (environment.exists("USERPROFILE")) 
            home = environment.get("USERPROFILE");
         else
         {
            Log.warn("HXCPP config might be missing(Environment has no \"HOME\" variable)");

            return null;
         }

         config = home + "/.hxcpp_config.xml";

         if (host == Platform.WINDOWS) 
         {
            config = config.split("/").join("\\");
         }
      }

      if (FileSystem.exists(config)) 
      {
         Log.verbose("Reading HXCPP config: " + config);
         readHxcppConfig = true;

         new NMMLParser(project,config,false);
      }
      else
      {
         Log.warn("", "Could not read HXCPP config: " + config);
      }
   }

   private static function getVersion():String 
   {
      var data = haxe.Json.parse(File.getContent(nme + "/haxelib.json"));
      return data.version;
   }

   #if (neko && haxe_210)
   public static function __init__ () 
   {
      // Fix for library search paths
      var path = PathHelper.getHaxelib(new Haxelib("nme")) + "ndll/";

      switch(PlatformHelper.hostPlatform) 
      {
         case WINDOWS:
            untyped $loader.path = $array(path + "Windows/", $loader.path);

         case MAC:
            untyped $loader.path = $array(path + "Mac/", $loader.path);

         case LINUX:
            var arguments = sys.args();
            var raspberryPi = false;

            for(argument in arguments) 
               if (argument == "-rpi") raspberryPi = true;

            if (raspberryPi) 
               untyped $loader.path = $array(path + "RPi/", $loader.path);
            else if (PlatformHelper.hostArchitecture == Architecture.X64) 
               untyped $loader.path = $array(path + "Linux64/", $loader.path);
            else
               untyped $loader.path = $array(path + "Linux/", $loader.path);

         default:
      }
   }
   #end

   static function loadProject(project:NMEProject,allowMissing:Bool) : Bool
   {
      Log.verbose("Loading project...");

      var projectFile = "";
      var targetName = "";
      var explicitProjectFile = false;

      for(w in 0...words.length)
      {
         var test = words[w].toLowerCase();
         if (isTarget(test))
         {
            targetName = test;
            words.splice(w,1);
            break;
         }
      }

      if (targetName=="" && project.hasDef("deploy"))
      {
         Log.verbose('Using default deployment target "cppia"');
         targetName = "cppia";
      }

      if (targetName=="" && (project.command=="icon" || project.command=="banner" || project.command=="favicon" ))
      {
         targetName = "cpp";
         Log.verbose('Using default nocompile target "$targetName"');
      }


      if (targetName=="")
      {
         if (words.length>1)
            Log.error("No valid target supplied. Try : " + allTargets.join(","));

         if (project.command=="nocompile")
         {
            targetName = "cpp";
            Log.verbose('Using default nocompile target "$targetName"');
         }
         else if (storeData.target!=null)
         {
            targetName = storeData.target;
            Log.verbose('Using target "$targetName" from settings');
         }
         else
         {
            targetName = "cpp";
            Log.verbose('Using default target "$targetName"');
         }
      }

      if (words.length>0)
      {
         if (FileSystem.exists(words[0])) 
         {
            if (FileSystem.isDirectory(words[0])) 
               projectFile = findProjectFile(words[0]);
            else
            {
               explicitProjectFile = true;
               projectFile = words[0];
            }
         }
      }
      else
         projectFile = findProjectFile(Sys.getCwd());


      if (projectFile == "") 
      {
         if (allowMissing)
            return true;

         if (assumedTest && words.length==0)
            return false;

         Log.error("You must have a \"project.nmml\" file or specify another valid project file when using the '" + command + "' command in " + Sys.getCwd());
      }
      else
         Log.verbose("Using project file: " + projectFile);

      project.checkRelocation( new Path(projectFile).dir );
      if (projectFile!=null)
         project.setProjectFilename(projectFile);

      project.haxedefs.set("nme_install_tool", "1");
      project.haxedefs.set("nme_ver", nmeVersion);
      project.haxedefs.set("nme" + nmeVersion.split(".")[0], "1");

      project.setTarget(targetName);

      if (staticFlag && project.optionalStaticLink)
         project.staticLink = true;

      getHXCPPConfig(project);

      if (host == Platform.WINDOWS) 
      {
         if (targetName=="cpp" && project.hasDef("HXCPP_MINGW"))
         {
            project.staticLink = true;
            project.haxedefs.set("no_shared_libs","1");
         }

         if (project.environment.exists("JAVA_HOME")) 
            Sys.putEnv("JAVA_HOME", project.environment.get("JAVA_HOME"));

         if (Sys.getEnv("JAVA_HOME") != null) 
         {
            var javaPath = PathHelper.combine(Sys.getEnv("JAVA_HOME"), "bin");

            if (host == Platform.WINDOWS) 
               Sys.putEnv("PATH", javaPath + ";" + Sys.getEnv("PATH"));
            else
               Sys.putEnv("PATH", javaPath + ":" + Sys.getEnv("PATH"));
         }
      }

      try { Sys.setCwd(Path.directory(projectFile)); } catch(e:Dynamic) {}

      var ext =  Path.extension(projectFile);
      var projFile = Path.withoutDirectory(projectFile);
      if (ext == "nmml" || ext == "xml") 
      {
         new NMMLParser(project,projFile,true);
      }
      else if (ext=="hx")
      {
         new HxParser(project,projFile);
      }
      else if (ext=="nme")
      {
         runAcadnme([projFile],project);
      }
      else
      {
         var loaded = false;
         if (explicitProjectFile)
         {
            try
            {
               new NMMLParser(project,projFile,true);
               loaded = true;
            }
            catch(e:Dynamic)
            {
               Log.warn(e);
            }
         }

         if (!loaded)
         {
            Log.error(projectFile + " does not appear be a project file.");
            return false;
         }
      }

      project.localDefines.set("PROJECT_FILE", projFile);

      if ( (project.hasDef("scriptable") || project.target==Platform.CPPIA) && project.hasDef("CPPIA_CLASSPATH"))
      {
         var include = project.getDef("CPPIA_CLASSPATH") + "/include.xml";
         if (FileSystem.exists(include))
         {
            Log.verbose("Read from CPPIA_CLASSPATH " + include); 
            new NMMLParser(project,include,true);
         }
      }

      project.processLibs();

      // Better way to do this?
      switch(project.target) 
      {
         case Platform.ANDROID, Platform.IOS,
              Platform.IOSVIEW, Platform.ANDROIDVIEW:

            getBuildNumber(project);

         default:
      }

      project.templatePaths.push( nme + "/templates" );

      return true;
   }

   private static function resolveClass(name:String):Class<Dynamic> 
   {
      if (name.toLowerCase().indexOf("project") > -1) 
      {
         return NMEProject;
      }
      else
      {
         return Type.resolveClass(name);
      }
   }

   public static function isIn(array:Array<String>,inValue:String)
   {
      for(a in array)
         if (a==inValue)
            return true;
      return false;

   }

   public static function isCommand(inCommand:String)
   {
      return isIn(allCommands,inCommand);
   }

   public static function isTarget(inTarget:String)
   {
      return isIn(allTargets,inTarget);
   }


   public static function setValue()
   {
      if (words.length==2 || isIn(setNames,words[0]))
      {
         Reflect.setField(storeData, words[0], words[1]);
         store.flush();
      }
      else if (words.length==1 || isIn(quickSetNames,words[0]))
      {
         Reflect.setField(storeData, words[0], true);
         store.flush();
      }
      else
      {
         sys.println("Usage : nme set name [value]");
         for(n in 0...setNames.length)
         {
            sys.println(" " + setNames[n] + " : " + setNamesHelp[n]);
            sys.println("    = " + Reflect.field(storeData, setNames[n]) );
         }
         for(name in quickSetNames)
         {
            sys.println(' $name [' + (Reflect.field(storeData,name)==null ? "not set" : "set") + ']' );
         }
      }
   }


   public static function getValue(inValue:String) : Dynamic
   {
      return Reflect.field(storeData, inValue);
   }



   public static function unsetValue()
   {
      if (words.length!=1 || !(isIn(setNames,words[0]) || isIn(quickSetNames,words[0])) )
      {
         sys.println("Usage : nme unset name");
         sys.println(" name : " + setNames.concat(quickSetNames).join(",") );
      }
      else
      {
         Reflect.deleteField(storeData, words[0]);
         store.flush();
      }
   }

   static function buildNdll()
   {
      sys.println("The binary nme.ndll is not distrubuted with source code, and is not built for your system yet.");
      while(true)
      {
         Sys.print("Would you like to build it now Y/n ? >");
         var result = Sys.stdin().readLine();
         if (result.substr(0,1).toLowerCase()=="n")
            return;
         if (result.substr(0,1).toLowerCase()=="y" || result=="")
         {
            sys.println("Update nme-dev...");
            ProcessHelper.runCommand("", "haxelib", ["update","nme-dev"]);
            sys.println("Build binaries...");
            ProcessHelper.runCommand(nme + "/project", "neko", ["build.n"] );
            sys.println("\nPlease re-run nme");
            return;
         }
      }
   }

   public static function rebuild(project:NMEProject)
   {
      new hxcpp.Builder(additionalArguments);
   }

   public static function runNme(project:NMEProject)
   {
      if (words.length!=1)
         Log.error("Expected nme file.nme [-args extra args]");

      var fullPath =  FileSystem.fullPath(words[0]);

      runAcadnme([fullPath].concat(additionalArguments));
   }

   public static function init():Void {
      sys = new RealSys();
   }

   public static function main():Void 
   {
      if(sys == null)
          init();

      nme = PathHelper.getHaxelib(new Haxelib("nme"));

      if (!Loader.foundNdll)
      {
         buildNdll();
         return;
      }

      var project = new NMEProject( );
      project.localDefines.set("NME",nme);

      traceEnabled = null;

      additionalArguments = new Array<String>();

      command = "";

      words = new Array<String>();

      store = SharedObject.getLocal("nme-run");
      storeData = store.data;

      if (storeData.verbose!=null)
      {
         Sys.putEnv("HXCPP_VERBOSE","1");
         Log.mVerbose = true;
         Log.verbose("Using verbose option from setting");
      }

      if (storeData.debug!=null)
      {
         project.setDebug(debug = true);
         Log.verbose("Using debug option from setting");
      }


      // Haxelib bug
      for(hackDir in ["Linux","Linux64", Sys.systemName(), Sys.systemName()+"64" ])
      {
         try
         {
            if (FileSystem.exists("ndll") && !FileSystem.exists("ndll/" + hackDir) )
                FileSystem.createDirectory("ndll/" + hackDir);
         }
         catch(e:Dynamic) { }
      }


      processArguments(project);

      if (storeData.cppiaClassPath!=null && !project.hasDef("CPPIA_CLASSPATH") )
         project.localDefines.set("CPPIA_CLASSPATH", storeData.cppiaClassPath);
      if (storeData.cppiaHost!=null)
         project.localDefines.set("CPPIA_HOST", storeData.cppiaHost);
      if (storeData.developmentTeam!=null && !project.hasDef("DEVELOPMENT_TEAM"))
         project.localDefines.set("DEVELOPMENT_TEAM", storeData.developmentTeam);


      if (Log.mVerbose && command!="") 
      {
         displayInfo(false, command=="xcode" || quick);
         sys.println("");
      }

      switch(command) 
      {
         case "":
            displayInfo(true);

         case "nme":
            runNme(project);

         case "rebuild":
            rebuild(project);

         case "help":
            displayHelp();

         case "set":
            setValue();

         case "unset":
            unsetValue();

         case "setup":
            setup();

         case "document":
            document();

         case "generate":
            generate();

         case "clone":
            processSample(project,"clone");

         case "demo":
            processSample(project,"demo");

         case "create":
            createTemplate();

         case "shell":
            var deploy = project.hasDef("deploy") ? project.getDef("deploy") : getValue("deploy");
            var parsed = parseDeploy(deploy,true,true);
            Client.log = Log.verbose;
            Client.error = function(s) Log.error(s);
            Client.shell(parsed.name,additionalArguments,project.app.packageName);

         case "xcode":
            Sys.putEnv("HXCPP_NO_COLOUR","1");
            if (Sys.getEnv("NME_ALREADY_BUILDING")=="BUILDING")
               sys.println("...already building");
            else
               buildProject(project);

         case "clean", "update", "build", "run", "rerun", "install", "installer", "uninstall", "trace", "test", "tidy", "nocompile":

            if (words.length > 2) 
            {
               Log.error("Incorrect number of arguments for command '" + command + "'");
               return;
            }

            buildProject(project);

         case "copy-if-newer":
            // deprecated?

         case "icon":
            createIcon(project,false);

         case "favicon":
            createIcon(project,false,true);

         case "listbrowsers":
            platforms.EmscriptenPlatform.listBrowsers();

         case "banner":
            createIcon(project,true);

         default:

            Log.error("'" + command + "' is not a valid command");
      }
   }

   public static function parseDeploy(inDeploy:String, inRequire:Bool, inForScript:Bool)
   {
      if (inDeploy==null || inDeploy=="")
      {
         if (inRequire)
            Log.error("A deployment target must be specified with 'deploy=...' or set deploy ...");
         return null;
      }

      var parts = inDeploy.split(":");
      var protocol = parts.shift();
      var name = parts.join(":");

      if (name=="")
          return { protocol:"script", name:inDeploy };
      return { protocol:protocol, name:name };
   }

   public static function createIcon(project:NMEProject, inBanner:Bool, favIcon = false)
   {
      var width = 0;
      var height = 0;
      var name = words[0];
      if (words.length==3 && !favIcon)
      {
         width = Std.parseInt(words[1]);
         height = Std.parseInt(words[2]);
      }

      if ( (!favIcon && (width==0 || height==0)) || name==null)
         Log.error("Usage: nme icon iconname.png width height");

      words.splice(0,3);

      if (!loadProject(project,false))
         Log.error("Could not load project");

 
      var ok = favIcon ? 
         IconHelper.createWindowsIcon(project.icons, name, favIcon) :
         IconHelper.createIcon(inBanner?project.banners:project.icons, width, height, name );

      if (!ok)
         Log.error('Could not create $name icon $width x $height');

      if (favIcon)
         Log.verbose("Created " + name);
      else
         Log.verbose("Created " + name + " " + width + "x" + height );

   }

   // Assume haxever > 3.2 now
   /*
   public static function getHaxeVer()
   {
      if (haxeVer==null)
      {
         var vers = ProcessHelper.getOutput("haxe", ["-cp", nme+"/tools/haxe_ver", "--run", "HaxeVer.hx"] );
         haxeVer = vers[0];
      }

      return haxeVer;
   }
   */


   private static function processArguments(project:NMEProject):Void 
   {
      var arguments = sys.args();

      var lastCharacter = nme.substr( -1, 1);
      if (lastCharacter == "/" || lastCharacter == "\\") 
         nme = nme.substr(0, -1);

      nmeVersion = getVersion();

      if (arguments.length > 0) 
      {
         // When the command-line tools are called from haxelib, 
         // the last argument is the project directory and the
         // path to NME is the current working directory 
         var lastArgument = "";
         for(i in 0...arguments.length) 
         {
            lastArgument = arguments.pop();
            if (lastArgument.length > 0) break;
         }

         lastArgument = new Path(lastArgument).toString();
         if (((StringTools.endsWith(lastArgument, "/") && lastArgument != "/") ||
               StringTools.endsWith(lastArgument, "\\")) &&
               !StringTools.endsWith(lastArgument, ":\\")) 
            lastArgument = lastArgument.substr(0, lastArgument.length - 1);

         if (FileSystem.exists(lastArgument) && FileSystem.isDirectory(lastArgument)) 
            Sys.setCwd(lastArgument);
      }

      project.localDefines.set("DOCS", Fs.getDocs());
      project.localDefines.set("DESKTOP", Fs.getDesktop());

      command = "";

      var argIdx = 0;
      while(argIdx < arguments.length)
      {
         var argument = arguments[argIdx++];

         var equals = argument.indexOf("=");
         if (equals > 0) 
         {
            var argValue = argument.substr(equals + 1);
            // if quotes remain on the argValue we need to strip them off
            // otherwise the compiler really dislikes the result!
            var r = ~/^['"](.*)['"]$/;
            if (r.match(argValue)) 
               argValue = r.matched(1);

            if (argument.substr(0, 2) == "-D") 
               project.haxedefs.set(argument.substr(2, equals - 2), argValue);
            else if (argument.substr(0, equals) == "-device") 
               project.targetFlags.set("device",argValue);
            else if (argument.substr(0, 2) == "--") 
            {
               // this won't work because it assumes there is only ever one of these.
               //projectDefines.set(argument.substr(2, equals - 2), argValue);
               var field = argument.substr(2, equals - 2);

               if (field == "haxedef") 
                  project.haxedefs.set(argValue,"1");
               else if (field == "haxeflag") 
                  project.haxeflags.push(argValue);
               else if (field == "macro") 
                  project.macros.push(StringTools.replace(argument, "macro=", "macro "));
               else if (field == "haxelib") 
               {
                  var name = argValue;
                  var version = "";

                  if (name.indexOf(":") > -1) 
                  {
                     version = name.substr(name.indexOf(":") + 1);
                     name = name.substr(0, name.indexOf(":"));
                  }

                  project.haxelibs.push(new Haxelib(name, version));
               }
               else if (field == "source" || field=="cp" ) 
                  project.classPaths.push(argValue);
               else if (field == "xcodeconfig" ) 
               {
                  if (argValue=="Debug")
                     project.setDebug(debug = true);
               }
               else
                  project.localDefines.set(field, argValue);
            }
            else
            {
               project.localDefines.set(argument.substr(0, equals), argValue);
            }
         }
         else if (argument == "-deploy" || argument=="deploy") 
         {
            var value = getValue("deploy");
            if (value==null)
               Log.error("No deployment target set, use 'set deploy ...' or 'deploy=...'");
            project.localDefines.set("deploy", value);
         }
         else if (argument.substr(0, 1) == "-") 
         {
            if (argument.substr(1, 1) == "-") 
            {
               project.haxeflags.push(argument);
               if (argument == "--remap" || argument == "--connect") 
               {
                  project.haxeflags.push(argument);
                  project.haxeflags.push(arguments[argIdx++]);
               }
            }
            else if (argument == "-bin") 
               binDirOverride = arguments[argIdx++];

            else if (argument.substr(0, 4) == "-arm") 
            {
               var name = argument.substr(1).toUpperCase();
               var value = Type.createEnum(Architecture, name);

               if (value != null) 
                  project.architectures.push(value);
            }
            else if (argument == "-64") 
               project.architectures.push(Architecture.X64);

            else if (argument == "-in") 
               sampleInDir = arguments[argIdx++];

            else if (argument == "-32") 
               project.architectures.push(Architecture.X86);

            else if (argument=="-gradle" || argument=="-Dgradle")
            {
               gradle = true;
               project.haxedefs.set("gradle", "1");
            }
            else if (argument=="-q" || argument=="-quick")
            {
               project.haxedefs.set("quick", "1");
            }
            else if (argument=="-fat")
            {
               project.haxedefs.set("fat", "1");
            }
            else if (argument=="-notoolkit" || argument=="-Dnotoolkit")
            {
               toolkit = false;
               project.localDefines.set("notoolkit", "");
            }
            else if (argument=="-browser")
            {
               browser = arguments[argIdx++];
            }
            else if (argument=="-nobrowser")
            {
               browser = "none";
            }
            else if (argument=="-toolkit-debug" || argument=="-Dtoolkit-debug")
            {
               project.localDefines.set("NATIVE_TOOLKIT_OPTIM_TAG", "debug");
            }
            else if (argument=="-toolkit-release" || argument=="-Dtoolkit-release")
            {
               project.localDefines.set("NATIVE_TOOLKIT_OPTIM_TAG", "release");
            }
            else if (argument.substr(0, 2) == "-D") 
               project.haxedefs.set(argument.substr(2), "");

            else if (argument == "-lib") 
            {
               var name = arguments[argIdx++];
               project.addLib(name,false);
            }

            else if (argument == "-static" || argument=="-s") 
               staticFlag = true;

            else if (argument.substr(0, 2) == "-l") 
               project.includePaths.push(argument.substr(2));

            else if (argument == "-f")
               forceFlag = true;

            else if (argument == "-v" || argument == "-verbose") 
            {
               Sys.putEnv("HXCPP_VERBOSE","1");
               Log.mVerbose = true;
               if (project.haxeflags.indexOf("--times")<0)
                  project.haxeflags.push("--times");
            }
            else if (argument == "-times") 
            {
               if (project.haxeflags.indexOf("--times")<0)
                  project.haxeflags.push("--times");
            }
            else if (argument == "-vv" || argument == "-vverbose") 
            {
               project.haxeflags.push("-v");
               Sys.putEnv("HXCPP_VERBOSE","1");
               Log.mVerbose = true;
            }
            else if (argument == "-args")
            {
               while(argIdx < arguments.length)
                   additionalArguments.push(arguments[argIdx++]);
            }
            else if (argument == "-notrace") 
               traceEnabled = false;

            else if (argument == "-debug") 
            {
               project.setDebug(debug = true);
            }
            else if (argument == "-megatrace")
               project.setDebug(project.megaTrace = debug = true);

            else
               project.targetFlags.set(argument.substr(1), "");
         }
         // No '-'
         else
         {
            words.push(argument);
            if (argument=="rebuild")
               while(argIdx < arguments.length)
                  additionalArguments.push(arguments[argIdx++]);
         }
      }

      toolkit = !project.hasDef("notoolkit");
      if (toolkit && !project.haxedefs.exists("toolkit"))
         project.haxedefs.set("toolkit","");

      if (toolkit)
         project.localDefines.set("STATIC_NME","1");

      if (toolkit && readHxcppConfig && !project.hasDef("HXCPP_COMPILE_CACHE"))
      {
         Log.warn("Using toolkit without HXCPP_COMPILE_CACHE can lead to slow compile times.");
         Log.warn(" try adding the following line in your .hxcpp_config.xml file:");
         Log.warn("   <set name='HXCPP_COMPILE_CACHE' value='some_dir/.hxcpp_cache' />");
      }

      for(w in 0...words.length)
      {
         if (isCommand(words[w]))
         {
            command = words[w];
            words.splice(w,1);
            break;
         }
      }

      if (command=="" && words.length==1 && words[0].endsWith(".nme"))
         command = "nme";

      if (command=="" && storeData.command!=null)
      {
         command = storeData.command;
         Log.verbose('Using command "$command" from settings');
      }

      if (binDirOverride=="" && storeData.bin!=null)
      {
         binDirOverride = storeData.bin;
         Log.verbose('Using binDir "$binDirOverride" from settings');
      }

      if (command=="")
      {
         if (!Log.mVerbose)
            displayInfo(true);
         command = "test";
         assumedTest = true;
      }

      project.setCommand(command);
   }
}


