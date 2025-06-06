package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;
using StringTools;

class EmscriptenPlatform extends DesktopPlatform
{
   private var applicationDirectory:String;
   private var applicationMain:String;
   private var executableFile:String;
   private var executablePath:String;
   private var ext:String;
   private var sdkPath:String;
   private var python:String;
   private var memFile:Bool;
   var htmlOut = false;

   override public function getOutputExtra() : String { return "wasm"; }

   public function new(inProject:NMEProject)
   {
      super(inProject);

      setupSdk();

      htmlOut = true; //project.hasDef("EMSCRIPTEN_HTML");
      ext = htmlOut ? ".html" : ".js";
      applicationDirectory = getOutputDir();


      applicationMain = project.app.file;
      executableFile = applicationMain + ".js";
      executablePath = applicationDirectory + "/" + executableFile;
      outputFiles.push(executableFile);
      outputFiles.push(applicationMain + ".wasm");

      project.haxeflags.push('-D exe_link');
      project.haxeflags.push('-D HXCPP_LINK_EMSCRIPTEN_EXT=$ext');
      project.haxeflags.push('-D HXCPP_LINK_MEMORY_GROWTH=1');

      memFile = project.getBool("emscriptenMemFile", false);
      if (memFile)
      {
         project.haxeflags.push('-D HXCPP_LINK_MEM_FILE=1');
         outputFiles.push(applicationMain + ".mem");
      }
   }

   override public function getPlatformDir() : String { return "wasm"; }
   override public function getBinName() : String { return "Wasm"; }
   override public function getNativeDllExt() { return ".js"; }
   override public function getLibExt() { return ".a"; }

   override public function copyBinary():Void 
   {
      var dbg = project.debug ? "-debug" : "";

      var src = haxeDir + '/cpp/ApplicationMain$dbg';

      FileHelper.copyFileReplace(src + ".js", applicationDirectory+'/$applicationMain.js',
        'ApplicationMain$dbg.wasm', applicationMain+".wasm", true );
      FileHelper.copyFile(src + ".wasm", applicationDirectory+'/$applicationMain.wasm');

      if ( project.icons!=null && project.icons.length>0)
      {
         var ico = "icon.ico";
         var iconPath = PathHelper.combine(applicationDirectory, ico);

         if (IconHelper.createWindowsIcon(project.icons, iconPath, true)) 
            outputFiles.push(ico);
      }
   }

   public function getJsImport(name:String) : String
   {
      var def = project.getDef(name);
      if (def==null)
         return null;
      try
      {
         return sys.io.File.getContent(def);
      }
      catch(e:Dynamic)
      {
         Log.error("Could not load Js part " + name + "->" + def);
      }
      return null;
   }

   function stripPreloader(script:String, flags:Array<String>):String
   {
      if (flags.indexOf('arrayiterator')>=0)
      {
         var len0 = script.length;
         var lines = script.split("\n");
         var newLines = [];
         var removing = false;
         for(line in lines)
         {
            if (removing)
            {
               if (line.startsWith("}"))
                  removing = false;
            }
            else if (line.indexOf("haxe_iterators")>=0)
               removing = true;
            else
               newLines.push(line);
         }
         script = newLines.join("\n");
         Log.verbose("Strip iterators " + (script.length<len0) );

      }
      return script;
   }


   override function generateContext(context:Dynamic)
   {
      super.generateContext(context);
      context.NME_JS = '$applicationMain.js';
      context.NME_MEM_FILE = memFile;
      context.NME_APP_JS = '$applicationMain.wasm';
      context.NME_JS_FOOTER = getJsImport("nmeJsFooter");
      context.NME_JS_HEADER = getJsImport("nmeJsHeader");
      context.EM_RUN_HOOKS = project.getBool("HXCPP_LINK_EMRUN", false );


      if (project.hasDef("preloadBg"))
         context.PRELOAD_BG = '"' + project.getDef("preloadBg") + '"';
      else
      {
         var bg = project.window.background;
         context.PRELOAD_BG = '"#' + StringTools.hex(bg,6) + '"';
      }

      if (project.hasDef("preloadFg"))
         context.PRELOAD_FG = '"' + project.getDef("preloadFg") + '"';
      else
      {
         var bg = project.window.background;
         var r = (bg>>16) & 0xff;
         var g = (bg>>8) & 0xff;
         var b = (bg) & 0xff;
         r = (r>=160) ? 0 : 255;
         g = (g>=160) ? 0 : 255;
         b = (b>=160) ? 0 : 255;
         var fg = (r<<16) | (g<<8) | b;
         context.PRELOAD_FG = '"#' + StringTools.hex(fg,6) + '"';
      }

      var preloader = project.getDef("preloader");
      if (!project.hasDef("nopreloader") )
      {
         if (preloader==null)
         {
            preloader = CommandLineTools.nme + "/ndll/Emscripten/preloader.js";
            Log.verbose('Using default preloader $preloader');
         }
         else
         {
            Log.verbose('Using specified $preloader');
         }
     }

      if (preloader!=null)
      {
         try {
            var script = File.getContent(preloader);

            var preloadStrip = project.getDef("preloadStrip");
            if (preloadStrip!=null)
            {
               script = stripPreloader(script, [for(s in preloadStrip.split(" ")) s.toLowerCase() ]);
            }
            context.NME_PRELOADER = script;
         }
         catch(e:Dynamic)
         {
            Log.error("Could not load preloader '" + preloader + "'");
         }
      }

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
      if (project.hasDef("pythonServe"))
      {
         var server = "" + project.getDef("pythonServe");
         if (server.endsWith(".py"))
            runPython(server,arguments);
         else
            runPython(arguments);
      }
      else
      {
         #if no_haxe_http
         throw("Can't serve files with no_haxe_http.  Try pythonServe=...");
         #else
         var verbose = true;
         var server = new nme.net.http.Server(
            new nme.net.http.FileServer([FileSystem.fullPath(applicationDirectory) ],
              new nme.net.http.StdioHandler( Sys.println ), verbose
               ).onRequest  );

         var port = 2323;
         server.listen(port);
         trace("Serving :" + port);
         new nme.net.URLRequest('http://localhost:$port/index.html' ).launchBrowser();

         server.untilDeath();
         #end
      }



      //var fullPath =  FileSystem.fullPath('$applicationDirectory/index.html');
      //new nme.net.URLRequest("file://" + fullPath).launchBrowser();
   }


   public function runPython(?pythonFile:String, arguments:Array<String>):Void 
   {
      var command = pythonFile!=null ? [pythonFile] : sdkPath==null ? [ "-m", "http.server" ] : [sdkPath + "/upstream/emscripten/emrun.py"];
      var source = "index.html";
      //var source = ext == ".html" ? Path.withoutDirectory(executablePath) : "index.html";
      var browser = CommandLineTools.browser;
      var browserOps = browser=="none" ? ["--no_browser"] : browser==null ? [] : ["--browser",browser];

      if (python!=null)
         PathHelper.addExePath( haxe.io.Path.directory(python) );

      ProcessHelper.runCommand(applicationDirectory, "python", command.concat(browserOps).concat([source]).concat(arguments) );
   }

   public function setupSdk()
   {
      var hasSdk = project.hasDef("EMSDK");
      if (hasSdk)
         sdkPath = project.getDef("EMSDK");

      var hasPython = project.hasDef("EMSDK_PYTHON");
      if (hasPython)
         python = project.getDef("EMSDK_PYTHON");

      var home = CommandLineTools.home;
      var file = home + "/.emscripten";
      if (!hasSdk && FileSystem.exists(file))
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



