package;

import sys.FileSystem;

class NDLL 
{
   public var haxelib:Haxelib;
   public var name:String;
   public var path:String;
   public var isStatic:Bool;
   public var importStatic:String;

   public function new(inName:String, inHaxelib:Haxelib, inIsStatic:Bool) 
   {
      name = inName;
      haxelib = inHaxelib;
      isStatic = inIsStatic;
      importStatic="";
      if (isStatic)
      {
         importStatic = "import " + haxelib.name + ".Static" +
            name.substr(0,1).toUpperCase()  + name.substr(1) + ";\n";
      }
   }

}
