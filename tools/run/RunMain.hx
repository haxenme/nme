import Array;
class RunMain
{
   public static function log(s:String) Sys.println(s);
   public static function showMessage()
   {
      log("This version of nme appears to be a source/developement version.");
      log("Before this can be used, you need to:");
      log(" 1. Build the binaries appropriate to your system(s), this can be done with:");
      log("     cd project");
      log("     haxelib run hxcpp ToolkitBuild.xml");
      log(" 2. Rebuild the main command-line tool, this can be done with:");
      log("     cd tools/nme");
      log("     haxe compile.hxml");
      log("   Note: this requires the 'gm2d' and 'format' libraries, which can be installed with:");
      log("     haxelib install gm2d");
      log("     haxelib install format");
      log(" 3. Optionally, build the acadnme tool, this can be done with:");
      log("     cd acadnme");
      log("     haxelib run nme cpp nocompile");
      log("     cd ../samples/AcadnmeBoot");
      log("     haxelib run nme cppia installer");
      log("     cd ../acadnme");
      log("     haxelib run nme cpp build");
      while(true)
      {
         Sys.print("\nWould you like to do this now [y/n/a(ll, including acadnme)]");
         var code = Sys.getChar(true);
         if (code<=32)
            break;
         var answer = String.fromCharCode(code);
         if (answer=="y" || answer=="Y" || answer=="a" ||  answer=="A" )
         {
            log("");
            setup(answer=="a" || answer=="A");
            executeNme();
            return;
         }
         if (answer=="n" || answer=="N")
            break;
      }
      log("");
   }

   public static function setup(acadnmeToo:Bool)
   {
      buildBinaries([]);
      log("Installing gm2d...");
      run("","haxelib", [ "install","gm2d"]);
      log("Installing format...");
      run("","haxelib", [ "install","format"]);
      compileTool();
      if (acadnmeToo)
         compileAcadnme();
      log("Initial setup complete.");
   }

   public static function buildBinaries(platforms:Array<String>)
   {
      log("Building binaries...");
      run("project","haxelib", ["run","hxcpp","ToolkitBuild.xml"]);
   }

   public static function compileTool()
   {
      log("Compiling nme tool...");
      run("tools/nme","haxe", [ "compile.hxml"]);
   }

   public static function compileAcadnme()
   {
      log("Compiling acadnme tool...");
      run("acadnme","haxelib", [ "run", "nme", "cpp", "nocompile"]);
      run("samples/AcadnmeBoot","haxelib", [ "run", "nme", "cppia", "installer"]);
      run("acadnme","haxelib", [ "run", "nme", "cpp", "build"]);
   }

   public static function run(dir:String, command:String, args:Array<String>)
   {
      var oldDir:String = "";
      if (dir!="")
      {
         oldDir = Sys.getCwd();
         Sys.setCwd(dir);
      }
      if (Sys.command(command,args)!=0)
         throw "Error running " + command + " " + args.join(" ");
      if (oldDir!="")
         Sys.setCwd(oldDir);
   }

   public static function executeNme()
   {
      try
      {
         return neko.vm.Loader.local().loadModule("./nme.n")!=null;
      }
      catch(e:Dynamic)
      {
         var s = Std.string(e);
         var notFound = "Module not found";
         if (s.indexOf(notFound)<0)
         {
            //trace("====="+s);
            neko.Lib.rethrow(e);
         }

      }
      return false;
   }

   public static function main()
   {
      // When the command-line tools are called from haxelib, 
      // the last argument is the project directory and the
      // path to NME is the current working directory
     if(isRemake())
         remake();
     else if (!executeNme())
         showMessage();

   }

    static function isRemake():Bool
    {
        return Sys.args()[0] == 'remake';
    }

    static function remake():Void {
        compileTool();
        buildBinaries(makePlatforms());
    }

    static function makePlatforms():Array<String>
    {
        var platforms:Array<String> = Sys.args();
        platforms.pop();
        platforms.shift();
        return platforms;
    }
}
