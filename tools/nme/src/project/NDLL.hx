package;

import sys.FileSystem;

class NDLL 
{
   public var name:String;
   public var path:String;
   public var isStatic:Bool;
   public var noCopy:Bool;
   public var haxelibName:String;
   public var importStatic:String;
   public var registerPrim:String;

   public function new(inName:String, inBasePath:String, inIsStatic:Bool, inHaxelibName:String, inNoCopy:Bool)
   {
      name = inName;
      path = inBasePath;
      isStatic = inIsStatic;
      noCopy = inNoCopy;
      haxelibName = inHaxelibName;
      importStatic="";
      registerPrim = null;
      if (isStatic)
        setStatic();
   }

   public function find(binDir:String, prefix:String, suffix:String):String 
   {
      if (haxelibName == "hxcpp") 
      {
         var dir = isStatic ? "lib/" : "bin/";
         return path + "/" + dir + binDir + "/" + prefix + name + suffix;
      }

      var dir = isStatic ? "lib/" : "ndll/";
      var result = path + "/" + dir + binDir + "/" + prefix + name + suffix;
      if (!FileSystem.exists(result) && isStatic)
      {
         var test = path + "/ndll/" + binDir + "/" + prefix + name + suffix;
         if (FileSystem.exists(test))
            result = test;
      }
      return result;
   }


   public function isHxcppLib() { return haxelibName=="hxcpp"; }

   public function setStatic()
   {
      isStatic = true;

      var importName = name == "mysql5" ? "mysql" : name;

      var className = "Static" + importName.substr(0,1).toUpperCase()  + importName.substr(1);

      var classPath = PathHelper.classPathFrom(path);
      var filename =  classPath + "/" + haxelibName + "/" + className + ".hx";
      if (FileSystem.exists(filename))
         importStatic = "import " + haxelibName + "." + className + ";\n";
      else
      {
         var flatName = name;
         flatName = flatName.split("-").join("");
         registerPrim = flatName + "_register_prims";
      }
   }

}
