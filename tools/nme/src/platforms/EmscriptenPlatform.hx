package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class EmscriptenPlatform extends DesktopPlatform
{
   private var applicationDirectory:String;
   private var executableFile:String;
   private var executablePath:String;
   private var ext:String;
   private var sdkPath:String;
   private var python:String;
   private var memFile:Bool;

   override public function getOutputExtra() : String { return ext==".js" ? "jsprime" : ""; }

   public function new(inProject:NMEProject)
   {
      super(inProject);

      setupSdk();

      ext = project.hasDef("EMSCRIPTEN_HTML") ? ".html" : ".js";
      applicationDirectory = getOutputDir();
      executableFile = "ApplicationMain" + ext;
      executablePath = applicationDirectory + "/" + executableFile;
      outputFiles.push(executableFile);
      project.haxeflags.push('-D exe_link');
      project.haxeflags.push('-D HXCPP_LINK_EMSCRIPTEN_EXT=$ext');
      project.haxeflags.push('-D HXCPP_LINK_EMRUN');

      memFile = project.getBool("emscriptenMemFile", true);

      project.haxeflags.push('-D HXCPP_LINK_MEM_FILE=' + (memFile?"1":"0") );
   }

   override public function getPlatformDir() : String { return "emscripten"; }
   override public function getBinName() : String { return "Emscripten"; }
   override public function getNativeDllExt() { return ".js"; }
   override public function getLibExt() { return ".a"; }


   override public function copyBinary():Void 
   {
      // Must keep the same name
      if (project.debug)
      {
         var src = haxeDir + "/cpp/ApplicationMain-debug";

         if (ext==".html") // no 'debug'
            FileHelper.copyFile(src + ext, applicationDirectory+"/ApplicationMain.html");
         else
            FileHelper.copyFile(src + ext, applicationDirectory+"/ApplicationMain-debug"+ext);

         // Needed of O2?
         if (memFile)
            FileHelper.copyFile(src + ext+".mem", applicationDirectory+"/ApplicationMain-debug"+ext + ".mem" );

         if (ext==".html")
            FileHelper.copyFile(src + ".js", applicationDirectory+"/ApplicationMain-debug.js");

      }
      else
      {
         var src = haxeDir + "/cpp/ApplicationMain";

         FileHelper.copyFile(src + ext, executablePath);
         // Needed of O2?
         if (memFile)
            FileHelper.copyFile(src + ext+".mem", executablePath+".mem");

         if (ext==".html")
            FileHelper.copyFile(src + ".js", applicationDirectory+"/ApplicationMain.js");
      }
   }

   override function generateContext(context:Dynamic)
   {
      super.generateContext(context);
      context.NME_LIB_JS = project.debug ? "ApplicationMain-debug.js" : "ApplicationMain.js";
      context.NME_MEM_FILE = memFile;
      context.NME_APP_JS = null;
   }


   function emrun(arguments:Array<String>):Void 
   {
      var command = sdkPath==null ? "emrun" : sdkPath + "/emrun";
      if (python!=null)
      {
         PathHelper.addExePath( haxe.io.Path.directory(python) );
         ProcessHelper.runCommand("", "python", [command].concat(arguments));
      }
      else
         ProcessHelper.runCommand("", command, arguments);
   }
   public static function listBrowsers():Void 
   {
      var proj = new NMEProject();
      CommandLineTools.getHXCPPConfig(proj);
      var instance = new EmscriptenPlatform(proj);
      instance.emrun(["--list_browsers"]);
      Sys.println("NME : Use --nobrowser for no launch, or");
      Sys.println("          -browser ID, for specific one");
   }

   override public function run(arguments:Array<String>):Void 
   {
      var command = sdkPath==null ? "emrun" : sdkPath + "/emrun";
      var source = ext == ".html" ? Path.withoutDirectory(executablePath) : "index.html";
      var browser = CommandLineTools.browser;
      var browserOps = browser=="none" ? ["--no_browser"] : browser==null ? [] : ["--browser",browser];
      if (python!=null)
      {
         PathHelper.addExePath( haxe.io.Path.directory(python) );
         ProcessHelper.runCommand(applicationDirectory, "python", [command].concat(browserOps).concat([source]).concat(arguments) );
      }
      else
         ProcessHelper.runCommand(applicationDirectory, command, [source].concat(browserOps).concat(arguments) );
   }

   public function setupSdk()
   {
      var hasSdk = project.hasDef("EMSCRIPTEN_SDK");
      if (hasSdk)
         sdkPath = project.getDef("EMSCRIPTEN_SDK");
      var hasPython = project.hasDef("EMSCRIPTEN_PYTHON");
      if (hasPython)
         python = project.getDef("EMSCRIPTEN_PYTHON");

      var home = CommandLineTools.home;
      var file = home + "/.emscripten";
      if (FileSystem.exists(file))
      {
         var content = sys.io.File.getContent(file);
         content = content.split("\r").join("");
         var value = ~/^(\w*)\s*=\s*'(.*)'/;
         for(line in content.split("\n"))
         {
            if (value.match(line))
            {
               var name = value.matched(1);
               var val= value.matched(2);
               if (!hasSdk && name=="EMSCRIPTEN_ROOT")
               {
                  sdkPath=val;
               }
               if (!hasPython && name=="PYTHON")
               {
                  python=val;
               }
            }
         }
      }

   }

}



