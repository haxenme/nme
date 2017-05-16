package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;


class JsPrimePlatform extends Platform
{
   private var sdkPath:String;
   private var python:String;

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

   public function new(inProject:NMEProject)
   {
      super(inProject);

      project.haxeflags.push('-js $haxeDir/ApplicationMain.js');
      if (inProject.hasDef("jsminimal"))
      {
         project.macros.push("--macro nme.macros.Exclude.exclude()");
      }
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

   override public function copyBinary():Void 
   {
      PathHelper.mkdir(getOutputDir());

      var src = haxeDir + "/ApplicationMain.js";
      if (project.hasDef("jsminimal"))
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
         File.saveContent(getOutputDir()+"/ApplicationMain.js",contents);
      }
      else
         FileHelper.copyFile(src, getOutputDir()+"/ApplicationMain.js");
   }

   override function generateContext(context:Dynamic)
   {
      super.generateContext(context);
      context.jsminimal = project.hasDef("jsminimal");
      if (project.hasDef("preloader"))
      {
         var preloader = project.getDef("preloader");
         try {
            context.NME_PRELOADER = File.getContent(preloader);
         }
         catch(e:Dynamic)
         {
            Log.error("Could not load preloader '" + preloader + "'");
         }
      }

      // Flixel is based on cpp & neko - need jsprime too
      if (project.findHaxelib("flixel")!=null)
          project.haxeflags.push("-D FLX_JOYSTICK_API" );

   }


   override public function updateExtra()
   {
      super.updateExtra();
      if (project.hasDef("jsminimal"))
      {
         var src = CommandLineTools.nme + "/ndll/Emscripten/nmeclasses.js";
         FileHelper.copyFile(src, getOutputDir()+"/nmeclasses.js");
      }
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

   override public function run(arguments:Array<String>):Void 
   {
      setupServer();
      var command = sdkPath==null ? "emrun" : sdkPath + "/emrun";
      var dir = getOutputDir();
      if (python!=null)
      {
         PathHelper.addExePath( haxe.io.Path.directory(python) );
         ProcessHelper.runCommand(dir, "python", [command].concat(["index.html"]).concat(arguments) );
      }
      else
         ProcessHelper.runCommand(dir, command, ["index.html"].concat(arguments) );
   }
}

