import sys.FileSystem;
import haxe.io.Path;


class Sample
{
   public var path:String;
   public var name:String;
   public var short:String;

   public function new(inPath:String, inName:String, inPrefix:String)
   {
      path = inPath;
      name = inName + (inPrefix==null ? "" : "   (" + inPrefix + ")");
      short = "";
   }

   public function toString()
   {
      if (short.length>0 && short.length < name.length)
         return "[" + short + "]" + name.substr(short.length);
      else
         return name;
   }

   public function makeShort(others:Array<Sample>)
   {
      var nameLen = name.length;
      var len = 1;
      while(len<nameLen && name.substr(len,1)>="0" && name.substr(len,1)<="9")
         len++;

      while(len<nameLen)
      {
         var test = name.substr(0,len);
         var found = false;
         for(other in others)
            if (other.name!=name && other.name.substr(0,len)==test)
            {
               found = true;
               break;
            }
         if (!found)
         {
            short = test;
            return;
         }
         len++;
      }
      short = name;
   }

   public static function projectOf(inBase:String)
   {
      switch(inBase)
      {
         case "openfl" : return "openfl-samples";
         case "flixel" : return "flixel-demos";
         default: return inBase;
      }
   }

   public static function looksLikeSampleDir(inDir:String) : Bool
   {
      var hxCount = 0;
      try
      {
         for(file in FileSystem.readDirectory(inDir))
         {
            var lower =  file.toLowerCase();
            if (lower.substr(0,1)=="." || lower == "common" || lower=="assets"
                  || lower=="include.xml" || lower=="extension.xml" )
               continue;

            var path = inDir + "/" + file;
            if (!FileSystem.isDirectory(path))
            {
               var ext = new Path(lower).ext;
               if (ext=="nmml" || ext=="xml")
               {
                  return true;
                  }
               if (ext=="hx")
                  hxCount++;
            }
         }
      }
      catch(e:Dynamic) { }

      return hxCount==1;
   }


   public static function fromDir(inDir:String, result:Array<Sample>, ?inPrefix:String ) : Bool
   {
      var subDirs = new Array<String>();

      try
      {
         for(file in FileSystem.readDirectory(inDir))
         {
            var lower =  file.toLowerCase();
            if (lower.substr(0,1)=="." || lower == "common" || lower=="assets")
               continue;
            var path = inDir + "/" + file;
            if (FileSystem.isDirectory(path))
            {
               if (looksLikeSampleDir(path))
                  result.push( new Sample(path,file,inPrefix) );
               else
                  subDirs.push(path);
            }

         }
      }
      catch(e:Dynamic) { }


      if (inPrefix==null)
      {
         if (result.length==0)
            for(dir in subDirs)
               fromDir(dir, result, new Path(dir).file);

         if (result.length>0)
            result.sort( function(a,b) return a.name > b.name ? 1 : -1 );

         for(r in result)
            r.makeShort(result);
      }

      return result.length>0;
   }
}
