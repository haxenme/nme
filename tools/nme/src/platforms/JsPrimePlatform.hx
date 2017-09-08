package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;


class JsPrimePlatform extends Platform
{
   private var sdkPath:String;
   private var python:String;

   var nmeJs:String;
   var nmeClassesJs:String;

   override public function getPlatformDir() : String { return "jsprime"; }
   override public function get_platform() : String { return "jsprime"; }
   override public function getBinName() : String { return "Emscripten"; }
   override public function getNdllExt() : String { return ".js"; }
   override public function getLibExt() : String { return ".js"; }
   override public function getNdllPrefix() : String { return ""; }
   override public function getOutputExtra() : String { return "jsprime"; }
   override public function getOutputDir() { return targetDir + "/" + project.app.file; }
   override public function getAssetDir() { return getOutputDir(); }
   override public function getExeDir() { return getOutputDir(); }
   override public function getLibDir() { return getExeDir(); }
   override public function getNativeDllExt() { return ".js"; }
   override public function getArchSuffix() { return ""; }

   var extraFlags = new Array<String>();

   public function new(inProject:NMEProject)
   {
      super(inProject);

      project.haxeflags.push('-js $haxeDir/ApplicationMain.js');
      extraFlags.push('-js $haxeDir/ApplicationMain.js');
      project.haxeflags.push('-D jsminimal');
      extraFlags.push('-D jsminimal');
      project.macros.push("--macro nme.macros.Exclude.exclude()");

      nmeJs = project.getDef("nmeJs");
      if (nmeJs==null)
         nmeJs = "/nme/" + nme.Version.name + "/Nme.js";
      nmeClassesJs = project.getDef("nmeClassesJs");
      if (nmeClassesJs==null)
         nmeClassesJs = "/nme/" + nme.Version.name + "/NmeClasses.js";
   }

   public function restoreState()
   {
      for(flag in extraFlags)
         project.haxeflags.remove(flag);
      project.macros.remove("--macro nme.macros.Exclude.exclude()");
   }

   static function parseClassInfo(externs:Map<String,Bool>, filename:String)
   {
      if (sys.FileSystem.exists(filename))
      {
         var file = sys.io.File.read(filename);
         trace(filename);
         try
         {
            while(true)
            {
               var line = file.readLine();
               var parts = line.split(" ");
               if (parts[0]=="class" || parts[0]=="interface" || parts[0]=="enum" || parts[0]=="abstract")
                  externs.set(parts[1],true);
            }
         } catch( e : Dynamic ) { }
         if (file!=null)
            file.close();
      }
   }

   override public function updateAssets() { }

   public function getScriptName()
   {
      return haxeDir + "/ApplicationMain.js";
   }

   override public function copyBinary():Void 
   {
      copyOutputTo(getOutputDir());
   }

   public function copyOutputTo(destDir:String):Void
   {
      PathHelper.mkdir(destDir);

      var src = haxeDir + "/ApplicationMain.js";
      if (true || project.hasDef("jsminimal"))
      {
         var exportMap = new Map<String,Bool>();
         parseClassInfo(exportMap, CommandLineTools.nme + "/ndll/Emscripten/export_classes.info");
         var exports = {};
         for(name in exportMap.keys())
         {
            var parts = name.split(".");
            var root = exports;
            for(p in 0...parts.length)
            {
               var part = parts[p];
               if (p==parts.length-1)
                  Reflect.setField(root,part,"$hxClasses[\"" + name + "\"]");
               else
               {
                  var next = Reflect.field(root,part);
                  if (next==null)
                     Reflect.setField(root,part,next ={} );
                  root = next;
               }
            }
         }
         var defs = new Array<String>();
         defs.push("var __map_reserved = window.__map_reserved;");
         for(f in Reflect.fields(exports))
         {
            defs.push('var $f = ' + "$" + 'hxClasses.package.$f;');
            /*
            var val = Reflect.field(exports,f);
            if (!Std.is(val,String))
            {
               var str = haxe.Json.stringify(val);
               str = str.split("\\\"").join("'");
               str = str.split("\"").join("");
               val = str.split("'").join("\"");
            }
            defs.push('var $f = $val;');
            */
         }
         defs.push("");
         var classDefInject = defs.join("\n");

         var hxClassesDef = ~/hxClasses/;
         var extendFunc = ~/extend/;

         var hxClassesOverride = "if (typeof($global['hxClasses'])=='undefined') $global['hxClasses']=$hxClasses else $hxClasses=$global['hxClasses'];";
         var hxClassesSet = "var $hxClasses = (typeof($global['hxClasses'])=='undefined') ? {} : $global['hxClasses'];";

         var contents = File.getContent(src);
         var lastPos = 0;
         for(pos in 0...contents.length)
         {
            if (contents.charCodeAt(pos)=='\n'.code)
            {
               var line = contents.substr(lastPos, pos-lastPos);
               if (hxClassesDef.match(line))
               {
                  contents = contents.substr(0,pos+1) + (hxClassesOverride+"\n") +
                            classDefInject + contents.substr(pos+1);
                  break;
               }
               else if (extendFunc.match(line))
               {
                  contents = contents.substr(0,lastPos+1) + (hxClassesSet+"\n") +
                            classDefInject + contents.substr(lastPos+1);
                  break;
               }

               lastPos = pos;
            }
         }
         File.saveContent(destDir+"/ApplicationMain.js",contents);
      }
      else
         FileHelper.copyFile(src, destDir+"/ApplicationMain.js");
      project.localDefines.set("jsScript",destDir+"/ApplicationMain.js");
   }

   override function generateContext(context:Dynamic)
   {
      super.generateContext(context);
      context.jsminimal = project.hasDef("jsminimal");

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
         if (preloader==null && !project.hasDef("nopreloader") )
         {
            preloader = CommandLineTools.nme + "/ndll/Emscripten/preloader.js";
            Log.verbose('Using default preloader $preloader');
         }
         else
         {
            Log.verbose('Using specified $preloader');
         }
     }

     context.PARSE_NME = File.getContent(CommandLineTools.nme + "/ndll/Emscripten/parsenme.js");

      if (preloader!=null)
      {
         try {
            context.NME_PRELOADER = File.getContent(preloader);
         }
         catch(e:Dynamic)
         {
            Log.error("Could not load preloader '" + preloader + "'");
         }
      }

      context.NME_IMMEDIATE_LOAD = false;
      context.NME_JS = nmeJs;
      context.NME_APP_JS = getNmeFilename();
      context.NME_CLASSES_JS = nmeClassesJs;
      context.NME_MEM_FILE = true;

      // Flixel is based on cpp & neko - need jsprime too
      if (project.findHaxelib("flixel")!=null)
      {
          extraFlags.push("-D FLX_JOYSTICK_API");
          project.haxeflags.push("-D FLX_JOYSTICK_API" );
      }

   }


   override public function updateExtra()
   {
      super.updateExtra();

      var src = CommandLineTools.nme + "/ndll/Emscripten/NmeClasses.js";
      FileHelper.copyFile(src, getOutputDir()+nmeClassesJs);
   }


   override public function updateOutputDir():Void 
   {
      super.updateOutputDir();
      var ico = "icon.ico";
      var iconPath = PathHelper.combine(getOutputDir(), ico);
      IconHelper.createWindowsIcon(project.icons, iconPath, true);
   }

   
   override public function remapName(dir:String,filename:String)
   {
      if (filename=="Nme.js")
         return getOutputDir() + nmeJs;
      return super.remapName(dir, filename);
   }


   public function setupServer()
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

   override public function buildPackage() createNmeFile();

   function runServer(dir:String, browser:String)
   {
      var port = 6931;
      Log.verbose("Running server @" + dir +":" + port );
      var handler = new nme.net.http.FileServer([dir], new nme.net.http.StdioHandler(Sys.println), Log.mVerbose);
      var server = new nme.net.http.Server(handler.onRequest);
      server.listen(port);

      if (browser!="none")
         new nme.net.URLRequest('http://localhost:$port/index.html' ).launchBrowser();

      server.untilDeath();
   }

   override public function run(arguments:Array<String>):Void 
   {
      if (project.hasDef("emserver"))
         setupServer();

      var browser = CommandLineTools.browser;
      var dir = FileSystem.fullPath(getOutputDir());

      if (!project.hasDef("emserver") || python==null || sdkPath==null)
      {
         runServer(dir,browser);
      }
      else
      {
         var browserOps = browser=="none" ? ["--no_browser"] : browser==null ? [] : ["--browser",browser];
         var command = sdkPath + "/emrun";

         PathHelper.addExePath( haxe.io.Path.directory(python) );
         ProcessHelper.runCommand(dir, "python", [command].concat(browserOps).concat(["index.html"]).concat(arguments) );
      }
   }
}

