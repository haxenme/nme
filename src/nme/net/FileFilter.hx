package nme.net;

import StringTools;

@:nativeProperty
class FileFilter
{
   public var description:String;
   public var extension(default,set):String;
   public var macType:String;
   var match:Array<String>;

   public function new(inDescription:String, inExtension:String, inMacType:String = null)
   {
     description = inDescription;
     extension = inExtension;
     macType = inMacType;
   }
 
   // Includes the "." or may be empty string
   public function getBestExtension()
   {
      for(m in match)
      {
         if (m!=".*" && m.substr(0,1)==".")
            return m;
      }
      for(m in match)
      {
         if (m!=".*")
            return "." + m;
      }
      return "";
   }

   function set_extension(inExtension:String)
   {
      match = [];
      extension = inExtension;
      if (extension!=null)
         for(part in extension.split(";"))
            if (part.length>0 && part.substr(0,1)=="*")
               match.push(part.toLowerCase().substr(1));
      return inExtension;
   }

   public function matches(inFilename:String)
   {
      var filename = inFilename.toLowerCase();
      var flen = filename.length;
      for(m in match)
      {
         if (m==".*")
            return true;
         if (m.length <= flen && filename.substr(flen-m.length)==m)
            return true;
      }
      return false;
   }
}

