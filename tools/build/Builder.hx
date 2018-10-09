import sys.FileSystem;
import sys.io.File;

class Builder extends hxcpp.Builder
{
   static var toolkitBuild = true;

   override public function getBuildFile()
   {
      if (toolkitBuild)
         return "ToolkitBuild.xml";
      else
         return "Build.xml";
   }

   override public function wantWindows64() { return true; }

   override public function showUsage(inShowSpecifyMessage:Bool)
   {
      Sys.println("Usage : neko build.n jsprime");
      Sys.println("  = build jsprime system");
      super.showUsage(inShowSpecifyMessage);
   }

   static function runCommand(exe:String, args:Array<String>)
   {
     Sys.println(exe + " " + args.join(" ") );
     if (Sys.command(exe, args)!=0)
     {
        Sys.println("#### Error, " + exe + " failed");
        Sys.exit(-1);
     }
   }

   static function setDir(inDir:String)
   {
      var dir = haxe.io.Path.normalize(inDir);
      Sys.println('cd $dir');
      Sys.setCwd(dir);
   }

   public static function updateZippedFile(src:String, dest:String, dataName:String)
   {
      if (!FileSystem.exists(dest) || FileSystem.stat(src).mtime.getTime() > FileSystem.stat(dest).mtime.getTime() )
      {
         Sys.println("Update " + dest);
         var bytes = File.getBytes(src);
         var zipped = haxe.zip.Compress.run(bytes,9);
         var fout = sys.io.File.write(dest,true);

         fout.writeString( 'int ${dataName}FullSize = ' + bytes.length + ";\n");
         fout.writeString( 'int ${dataName}CompressedSize = ' + zipped.length + ";\n");
         fout.writeString( 'const unsigned char ${dataName}DataBuffer[] = {\n  ');
         for(i in 0...zipped.length)
         {
            fout.writeString( zipped.get(i) + "," );
            if ( (i%20)== 19 ) fout.writeString("\n  ");
         }
         fout.writeString( '};\n');
         fout.writeString( 'const unsigned char *${dataName}Data = ${dataName}DataBuffer;\n  ');
         fout.close();
      }
   }


   public static function updateFontData()
   {
      // Relative to "project" directory
      updateZippedFile( "../assets/fonts/Arimo-Regular.ttf", "src/emscripten/_sans.cpp", "gSans" );
      updateZippedFile( "../assets/fonts/Cousine-Regular.ttf", "src/emscripten/_serif.cpp", "gSerif" );
      updateZippedFile( "../assets/fonts/Tinos-Regular.ttf", "src/emscripten/_monospace.cpp", "gMonospace" );
   }

   public static function buildJsPrime(args:Array<String>)
   {
      var cwd = Sys.getCwd();
      runCommand("haxelib", ["run","hxcpp","ToolkitBuild.xml","-Demscripten","-DHXCPP_JS_PRIME"]);
      setDir( cwd+"../tools/make_classes/");
      runCommand("haxe", ["--run","MakeClasses"]);
      setDir( cwd+"../tools/preloader/");
      runCommand("haxe", ["compile.hxml"]);
      setDir( cwd+"../tools/parsenme/");
      runCommand("haxe", ["compile.hxml"]);
   }

   public static function main()
   {
      var args = Sys.args();
      if (args.remove("-Dnme-dev"))
         toolkitBuild = false;

      if (args.indexOf("emscripten")>=0 || args.indexOf("jsprime")>=0)
         updateFontData();

      if (args.remove("jsprime"))
      {
         toolkitBuild = false;
         buildJsPrime(args);
      }
      else
      {
         new Builder( args );
      }
   }
}

