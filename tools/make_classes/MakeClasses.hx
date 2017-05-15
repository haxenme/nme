import sys.FileSystem;
import sys.io.File;
using StringTools;

class MakeClasses
{
   public static function findRecurse(inPath:String, inPackage:String,inFilter:String->Bool,outClasses:Array<String>)
   {
      for(file in FileSystem.readDirectory(inPath))
      {
         if (file.substr(0,1)!="." && inFilter(file))
         {
            var test = inPath+"/"+file;

            if (FileSystem.isDirectory(test))
               findRecurse(test,inPackage+"."+file,inFilter,outClasses);
            else
            {
               var hxName = inPackage+"."+file;
               if (hxName.substr(hxName.length-3)==".hx")
                  outClasses.push( hxName.substr(0,hxName.length-3) );
            }
         }
      }
   }

   static var exclude = [
      "android",
      "native",
      "image",
      "watchos",
      "SwfAssetLib.hx",
      "ios",
      "compat",
      "cpp",
      "macros",
      "JNI.hx",
      "FileServer.hx",
      "Server.hx",
      "script",
      "gl",
      "display3D",
      "Stage3D.hx",
      "preloader",
   ];
   static function keep(inName:String):Bool
   {
      return exclude.indexOf(inName)<0;
   }

   static function genExports(file:String)
   {
      var result = new Array<String>();
      for(line in file.split("\n"))
      {
         var parts = line.split(" ");
         if (parts[0]=="class" || parts[0]=="interface" || parts[0]=="enum")
         {
            var e = parts[1];
            result.push('  classes.$e = $e;');
         }
      }
      return result;
   }

   static function filterContents(contents:String)
   {
      return contents.split("\n").filter(function(s) {
         var s = s.split(" ")[1];
         return s!=null && !(s.startsWith("Export") ||
                             s.startsWith("ImportAll") ||
                             s.startsWith("js.") ||
                             s.startsWith("haxe._") ||
                             s.startsWith("nme._") ||
                             s.startsWith("nme.text._") ||
                             s.startsWith("nme.utils._") ||
                             s.startsWith("haxe.ds") ||
                             s.startsWith("haxe.extern._") ||
                             s.startsWith("haxe.xml._") ||
                             s.startsWith("haxe.IMap") ||
                             s.startsWith("cpp._") ||
                             s.startsWith("_") ||
                             s.startsWith("ValueType") ||
                             s.startsWith("haxe.EnumValueTools") ||
                             s.startsWith("haxe.macro") );
      }).join("\n");
   }



   public static function main()
   {
      Sys.println('Find classes...');
      var classes = new Array<String>();
      findRecurse("../../nme","nme",keep,classes);
      findRecurse("../../haxe","haxe",keep,classes);
      classes = classes.concat([
         "List",
         "haxe.CallStack",
         "Xml",
         "haxe.xml.Parser",
      ]);

      Sys.println('Create wrapper...');
      var lines = new Array<String>();
      for(cls in classes)
         lines.push('import $cls;');
      lines.push("class ImportAll {");
      lines.push("  public static function main(classes:Dynamic) {");
      lines.push(" }");
      lines.push("}");

      FileSystem.createDirectory("gen");
      File.saveContent("gen/ImportAll.hx", lines.join("\n"));

      Sys.println('Generate pass 1...');
      var result = Sys.command("haxe",["-main","Export","-cp","gen","-cp","../..","-js","gen/nmeclasses.js","-dce","no","-D","jsprime","-D","js-unflatten"] );
      if (result!=0)
         Sys.exit(result);

      var contents = File.getContent("gen/export_classes.info");
      contents = filterContents(contents);
      var exports = genExports(contents);

      Sys.println('Generate pass 2...');
      lines.pop();
      lines.pop();
      lines = lines.concat(exports).concat([" }","}"]);
      File.saveContent("gen/ImportAll.hx", lines.join("\n"));

      var result = Sys.command("haxe",["-main","Export","-cp","gen","-cp","../..","-js","gen/nmeclasses.js","-dce","no","-D","jsprime","-D","js-unflatten"] );
      if (result!=0)
         Sys.exit(result);

      Sys.println("Export...");
      FileSystem.createDirectory("../../ndll");
      FileSystem.createDirectory("../../ndll/Emscripten");

      var hxClassesDef = ~/hxClasses/;

      var inject = "if (typeof($global['hxClasses'])=='undefined') $global['hxClasses']=$hxClasses else $hxClasses=$global['hxClasses'];";
      var src = File.getContent("gen/nmeclasses.js");
      var lastPos = 0;
      for(pos in 0...src.length)
      {
         if (src.charCodeAt(pos)=='\n'.code)
         {
            if (hxClassesDef.match(src.substr(lastPos, pos-lastPos)))
            {
               src = src.substr(0,pos+1) + (inject+"\n") + src.substr(pos+1);
               break;
            }
            lastPos = pos;
         }
      }

      /*
       Interp mode does not like big split ...
      var lines = src.split("\n");
      */

      File.saveContent("../../ndll/Emscripten/nmeclasses.js",src);

      File.saveContent("../../ndll/Emscripten/export_classes.info",contents);

      Sys.println("Gen exports.");

      Sys.println("Done.");

      Sys.exit(result);
   }
}
