import sys.FileSystem;


class Sample
{
   public var path:String;
   public var name:String;
   public var short:String;

   public function new(inPath:String, inName:String, inShort:String="")
   {
      path = inPath;
      name = inName;
      short = inShort;
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

   public static function fromDir(inDir:String)
   {
      var result = new Array<Sample>();

      try
      {
         for(file in FileSystem.readDirectory(inDir))
         {
            var lower =  file.toLowerCase();
            if (lower.substr(0,1)=="." || lower == "common" || lower=="assets")
               continue;
            var path = inDir + "/" + file;
            if (FileSystem.isDirectory(path))
               result.push( new Sample(path,file) );
         }
      }
      catch(e:Dynamic) { }

      if (result.length>0)
         result.sort( function(a,b) return a.name > b.name ? 1 : -1 );

      for(r in result)
         r.makeShort(result);

      return result;
   }
}
