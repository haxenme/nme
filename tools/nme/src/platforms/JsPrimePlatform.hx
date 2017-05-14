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

   override public function copyBinary():Void 
   {
      PathHelper.mkdir(getOutputDir());

      var src = haxeDir + "/ApplicationMain.js";
      if (project.hasDef("jsminimal"))
      {
         var hxClassesDef = ~/hxClasses/;
         var inject = "if (typeof($global['hxClasses'])=='undefined') $global['hxClasses']=$hxClasses else $hxClasses=$global['hxClasses'];";
         var contents = File.getContent(src);
         var lastPos = 0;
         for(pos in 0...contents.length)
         {
            if (contents.charCodeAt(pos)=='\n'.code)
            {
               if (hxClassesDef.match(contents.substr(lastPos, pos-lastPos)))
               {
                  contents = contents.substr(0,pos+1) + (inject+"\n") + contents.substr(pos+1);
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

