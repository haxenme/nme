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

   public function new(name:String, haxelib:Haxelib = null, registerStatics:Bool = true,inIsStatic=true) 
   {
      this.name = name;
      this.haxelib = haxelib;
      this.registerStatics = registerStatics;
      isStatic = inIsStatic;
   }

}
