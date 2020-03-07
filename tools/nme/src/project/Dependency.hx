using StringTools;
import sys.FileSystem;

// When used with js, name=name on server, path (if present) = source path
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
      var isAnt = FileSystem.exists( getAndroidProject() + "/project.properties" );
      var isGradle = FileSystem.exists( getAndroidProject() + "/build.gradle" );
      return isAnt || isGradle;
   }

   public function isFramework()
   {
      return name.endsWith(".framework") || path.endsWith(".framework");
   }

   public function isLibrary()
   {
      return name.endsWith(".a") || path.endsWith(".a");
   }



   public function getFramework()
   {
      if (name!="")
         return name;
      return path;
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

