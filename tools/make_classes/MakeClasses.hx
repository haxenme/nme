import sys.FileSystem;
import sys.io.File;

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
      "Type",
      "Reflect",
   ];
   static function keep(inName:String):Bool
   {
      return exclude.indexOf(inName)<0;
   }



   public static function main()
   {
      Sys.println('Find classes...');
      var classes = new Array<String>();
      findRecurse("../../nme","nme",keep,classes);
      findRecurse("../../haxe","haxe",keep,classes);

      Sys.println('Create wrapper...');
      var lines = new Array<String>();
      for(cls in classes)
         lines.push('import $cls;');
      lines.push("class ImportAll {");
      lines.push("   public static function main() { }");
      lines.push("}");

      FileSystem.createDirectory("gen");
      File.saveContent("gen/ImportAll.hx", lines.join("\n"));

      Sys.println('Generate ...');
      var result = Sys.command("haxe",["-main","Export","-cp","gen","-cp","../..","-js","gen/nmeclasses.js","-dce","no","-D","jsprime","-D","js-unflatten"] );

      Sys.println('Built with result $result.');
      if (result!=0)
         Sys.exit(result);

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
      var lines = src.split("\n");
      for(l in 0...lines.length)
      {
         if (hxClassesDef.match(lines[l]))
         {
            lines.insert(l,"if (typeof($global['hxClasses'])=='undefined') $global['hxClasses']=$hxClasses else $hxClasses=$global['hxClasses'];" );
            break;
         }
      }
      src = lines.join("\n");
      */

      File.saveContent("../../ndll/Emscripten/nmeclasses.js",src);

      var bytes = File.getBytes("gen/export_classes.info");
      File.saveBytes("../../ndll/Emscripten/export_classes.info",bytes);

      Sys.exit(result);
   }
}
