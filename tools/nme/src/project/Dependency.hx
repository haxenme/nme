using StringTools;
import sys.FileSystem;

class Dependency
{
   public var name:String;
   public var path:String;
   public var baseDir:String;
   public var sourceTree:String;

   public function new(inName:String, inPath:String, inBaseDir:String)
   {
      name = inName;
      path = inPath;
      baseDir = inBaseDir;
   }

   public function getAndroidProject()
   {
      return baseDir +"/" + path;
   }

   public function isAndroidProject()
   {
      return FileSystem.exists( getAndroidProject() + "/project.properties" );
   }

   public function isFramework()
   {
      return name.endsWith(".framework");
   }

   public function isLibrary()
   {
      return name.endsWith(".a");
   }



   public function getFramework()
   {
      return name;
   }



   public function makeUniqueName()
   {
      if (name=="")
         name = "dep" + haxe.crypto.Md5.make(haxe.io.Bytes.ofString(getFilename())).toHex();

      return name;
   }


   public function getFilename()
   {
      // Hmmm
      if (name.endsWith(".a") || name.endsWith(".dll"))
         return baseDir + "/" + path + "/" + name;
      return baseDir + "/" + path;
   }
}

