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
      var result = Sys.command("haxe",["-main","Export","-cp","gen","-cp","../..","-js","gen/nmeclasses.js","-dce","no","-D","jsprime"] );

      Sys.println('Built with result $result.');
      if (result!=0)
         Sys.exit(result);

      Sys.exit(result);
   }
}
