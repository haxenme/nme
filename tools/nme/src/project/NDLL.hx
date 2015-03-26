package;

import sys.FileSystem;

class NDLL 
{
   public var haxelib:Haxelib;
   public var name:String;
   public var path:String;
   public var isStatic:Bool;
   public var importStatic:String;
   public var allowMissing:Bool;

   public function new(inName:String, inHaxelib:Haxelib, inIsStatic:Bool, inAllowMissing:Bool) 
   {
      name = inName;
      haxelib = inHaxelib;
      isStatic = inIsStatic;
      importStatic="";
      allowMissing = inAllowMissing;
      if (isStatic)
      {
         var importName = name == "mysql5" ? "mysql" : name;
         importStatic = "import " + haxelib.name + ".Static" +
            importName.substr(0,1).toUpperCase()  + importName.substr(1) + ";\n";
      }
   }

}
