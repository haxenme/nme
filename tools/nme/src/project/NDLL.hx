package;

import sys.FileSystem;

class NDLL 
{
   public var haxelib:Haxelib;
   public var name:String;
   public var path:String;
   public var isStatic:Bool;
   public var importStatic:String;
   public var registerPrim:String;
   public var allowMissing:Bool;

   public function new(inName:String, inHaxelib:Haxelib, inIsStatic:Bool, inAllowMissing:Bool) 
   {
      name = inName;
      haxelib = inHaxelib;
      isStatic = inIsStatic;
      importStatic="";
      allowMissing = inAllowMissing;
      registerPrim = null;
      if (isStatic)
        setStatic();
   }

   public function setStatic()
   {
      isStatic = true;

      var importName = name == "mysql5" ? "mysql" : name;
      var className = "Static" + importName.substr(0,1).toUpperCase()  + importName.substr(1);

      var p = PathHelper.getHaxelib(haxelib);
      var filename =  p + "/" + haxelib.name + "/" + className + ".hx";
      if (FileSystem.exists(filename))
         importStatic = "import " + haxelib.name + "." + className + ";\n";
      else
      {
         var flatName = name;
         flatName = flatName.split("-").join("");
         registerPrim = flatName + "_register_prims";
      }
   }

}
