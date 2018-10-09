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
      "StaticNme.hx",
      "store",
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
         if (parts[0]=="class" || parts[0]=="interface" || parts[0]=="enum" || parts[0]=="abstract")
         {
            var e = parts[1];
            result.push(' "$e",');
         }
      }
      return result;
   }

   static function genPackages(file:String)
   {
      var result = new Array<String>();
      for(line in file.split("\n"))
      {
         var parts = line.split(" ");
         if (parts[0]=="class" || parts[0]=="interface" || parts[0]=="enum" || parts[0]=="abstract")
         {
            var e = parts[1];
            var path = e.split(".");
            if (result.indexOf(path[0])<0)
               result.push(path[0]);
         }
      }

      for(i in ["Any", "_Any", "_EReg", "EnumValue", "Void", "Null", "Bool", "ArrayAccess", "Sys", "UInt", "XmlType", "_Xml"] )
         result.remove(i);

      return result;
   }


   static function filterContents(contents:String)
   {
      return contents.split("\n").filter(function(s) {
         var s = s.split(" ")[1];
         return s!=null && !(s.startsWith("Export") ||
                             s.startsWith("ImportAll") ||
                             s.startsWith("haxe.macro") );
      }).join("\n");
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


   public static function main()
   {
      Sys.println('Find classes...');
      var classes = new Array<String>();
      findRecurse("../../src/nme","nme",keep,classes);
      findRecurse("../../src/haxe","haxe",keep,classes);
      classes = classes.concat([
         "List",
         "Reflect",
         "Type",
         "haxe.CallStack",
         "Xml",
         "haxe.xml.Parser",
      ]);

      Sys.println('Create wrapper...');
      var lines = new Array<String>();
      for(cls in classes)
         lines.push('import $cls;');
      lines.push("class ImportAll {");
      lines.push("}");

      FileSystem.createDirectory("gen");
      File.saveContent("gen/ImportAll.hx", lines.join("\n"));

      Sys.println('Generate pass 1...');
      runCommand("haxe",["-main","Export","-cp","gen","-cp","../../src","-js","gen/NmeClasses.js","-dce","no","-D","jsprime","-D","js-unflatten"] );

      var contents = File.getContent("gen/export_classes.info");
      contents = filterContents(contents);
      var exports = genExports(contents);
      var packages = genPackages(contents);

      runCommand("haxe",["-main","Export","-cp","gen","-cp","../../src","-js","gen/NmeClasses.js","-dce","no","-D","jsprime","-D","js-unflatten"] );

      Sys.println("Export...");
      FileSystem.createDirectory("../../ndll");
      FileSystem.createDirectory("../../ndll/Emscripten");

      var hxClassesDef = ~/hxClasses/;

      var inject = "if (typeof($global['hxClasses'])=='undefined')  { $global['hxClasses']=$hxClasses; }  else { $hxClasses=$global['hxClasses']; }";
      var src = File.getContent("gen/NmeClasses.js");
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

      var exportMain = src.indexOf("\nExport.main();");
      if (exportMain>0)
      {
         src = src.substr(0,exportMain+1) + "$hxClasses.package = {};\n" + packages.map(function(x) return "$hxClasses.package." + '$x = $x').join(";\n") +  src.substr(exportMain);
      }

      /*
       Interp mode does not like big split ...
      var lines = src.split("\n");
      */

      File.saveContent("../../ndll/Emscripten/NmeClasses.js",src);

      File.saveContent("../../ndll/Emscripten/export_classes.info",contents);

      Sys.println("Gen exports.");

      Sys.println("Done.");
   }
}
