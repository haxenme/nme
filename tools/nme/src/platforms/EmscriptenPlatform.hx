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
   var htmlOut = false;

   override public function getOutputExtra() : String { return "jsprime"; }

   public function new(inProject:NMEProject)
   {
      super(inProject);

      setupSdk();

      htmlOut = true; //project.hasDef("EMSCRIPTEN_HTML");
      ext = htmlOut ? ".html" : ".js";
      applicationDirectory = getOutputDir();


      executableFile = "ApplicationMain.js";
      executablePath = applicationDirectory + "/" + executableFile;
      outputFiles.push(executableFile);

      project.haxeflags.push('-D exe_link');
      project.haxeflags.push('-D HXCPP_LINK_EMSCRIPTEN_EXT=$ext');
      project.haxeflags.push('-D HXCPP_LINK_MEMORY_GROWTH=1');

      memFile = project.getBool("emscriptenMemFile", false);
      if (memFile)
         project.haxeflags.push('-D HXCPP_LINK_MEM_FILE=1');
   }

   override public function getPlatformDir() : String { return "emscripten"; }
   override public function getBinName() : String { return "Emscripten"; }
   override public function getNativeDllExt() { return ".js"; }
   override public function getLibExt() { return ".a"; }


   override public function copyBinary():Void 
   {
      var dbg = project.debug ? "-debug" : "";

      // Must keep the same name
      var src = haxeDir + '/cpp/ApplicationMain$dbg';
      if (htmlOut && false)
      {
         FileHelper.copyFile(src + ".html", applicationDirectory+"/index.html");
      }

      FileHelper.copyFile(src + ".js", applicationDirectory+'/ApplicationMain$dbg.js');
      FileHelper.copyFile(src + ".wasm", applicationDirectory+'/ApplicationMain$dbg.wasm');
   }

   override function generateContext(context:Dynamic)
   {
      super.generateContext(context);
      var dbg = project.debug ? "-debug" : "";
      context.NME_JS = 'ApplicationMain$dbg.js';
      context.NME_MEM_FILE = memFile;
      context.NME_APP_JS = 'ApplicationMain$dbg.wasm';
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
      if (false)
      {
         runPython(arguments);
      }
      else
      {
         var server = new nme.net.http.Server(
            new nme.net.http.FileServer([FileSystem.fullPath(applicationDirectory) ],
              new nme.net.http.StdioHandler( Sys.println ),
               ).onRequest  );

         var port = 2323;
         server.listen(port);
         trace("Serving :" + port);
         new nme.net.URLRequest('http://localhost:$port/index.html' ).launchBrowser();

         server.untilDeath();
      }



      //var fullPath =  FileSystem.fullPath('$applicationDirectory/index.html');
      //new nme.net.URLRequest("file://" + fullPath).launchBrowser();
   }


   public function runPython(arguments:Array<String>):Void 
   {
      var command = sdkPath==null ? "emrun" : sdkPath + "/emrun";
      var source = "index.html";
      //var source = ext == ".html" ? Path.withoutDirectory(executablePath) : "index.html";
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



