import sys.FileSystem;
using StringTools;

class Lyre
{

   public static function runRecurse(srcDir:String, destDir:String, copyDir:String, srcPack:String, destPack:String)
   {
      try
      {
         if (!FileSystem.exists(destDir))
            FileSystem.createDirectory(destDir);
         if (!FileSystem.exists(copyDir))
            FileSystem.createDirectory(copyDir);
         for(file in FileSystem.readDirectory(srcDir))
         {
            if (file=="_legacy")
               continue;

            var srcPath = srcDir +"/" + file;
            var destPath = destDir +"/" + file;
            var copyPath = copyDir +"/" + file;

            if (FileSystem.isDirectory(srcPath))
               runRecurse(srcPath, destPath, copyPath, srcPack+"."+file, destPack+"."+file);
            else if (file.endsWith(".hx"))
            {
               Sys.println("Writing " + destPath);
               var clazz = file.substr(0, file.length-3);
               var content = [
                   'package $destPack;',
                   'typedef $clazz=$srcPack.$clazz;',
                 ].join("\n");
               sys.io.File.saveContent(destPath,content);

               Sys.println("Copy " + copyPath);
               sys.io.File.copy(srcPath, copyPath);
            }
         }
      }
      catch(e:Dynamic)
      {
         trace("Error " + e);
      }
   }

   public static function main()
   {
      var args = Sys.args();
      var srcDir = args[0];
      var destDir = args[1];
      var packName = args[2];

      if (packName==null || !FileSystem.isDirectory(srcDir) || !FileSystem.isDirectory(destDir))
      {
         Sys.println("Usage : lyre srcDir destDir packageName");
         Sys.exit(0);
      }
      runRecurse(srcDir + "/" + packName, destDir + "/nme", destDir+"/"+packName, packName, "nme" );
   }
}
