package;

import sys.FileSystem;

class NDLL 
{
   public var extensionPath:String;
   public var haxelib:Haxelib;
   public var name:String;
   public var path:String;
   public var registerStatics:Bool;
   public var isStatic:Bool;
   public var importStatic:String;

   public function new(name:String, haxelib:Haxelib = null, registerStatics:Bool = true,inIsStatic=true) 
   {
      this.name = name;
      this.haxelib = haxelib;
      this.registerStatics = registerStatics;
      isStatic = inIsStatic;
      importStatic="";
      if (isStatic)
      {
         importStatic = "import " + haxelib.name + ".Static" +
            name.substr(0,1).toUpperCase()  + name.substr(1) + ";\n";
      }
   }

}
