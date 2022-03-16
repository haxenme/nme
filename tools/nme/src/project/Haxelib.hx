package;

class Haxelib 
{
   public var name:String;
   public var version:String;

   public function new(name:String, version:String = "") 
   {
      this.name = name;
      this.version = version;
   }

   public function getBase():String
   {
      return PathHelper.getHaxelib(this);
   }


   public function addLibraryFlags(outFlags:Array<String>)
   {
      var lib = name;

      if (version != "")
         lib += ":" + version;
      var paths = PathHelper.getHaxelibPath(lib);

      // Hmmm
      if (paths.length==0)
         outFlags.push("-lib " + lib);
      else
      {
         var soFar = new Array<String>();
         for(line in paths)
         {
            if (StringTools.trim(line).length == 0) // "haxelib path ..." can return blank lines
            {
               continue;
            }
            if (line.substr(0,2)=="-D")
            {
               var lib = line.substr(3).split("=")[0];
               Log.verbose("Adding library flags for " + lib);
               if (lib!="openfl" && lib!="lime")
               {
                  soFar.push(line);
                  for(s in soFar)
                    outFlags.push(s);
               }
               soFar = new Array<String>();
            }
            else if (line.substr(0,8)=="Library " || line.substr(0,3)=="-L ") 
            {
               // Hmmm
            }
            else if (line.substr(0,1)=="-")
            {
               // Add extraParam
               soFar.push(line);
            }
            else
            {
               soFar.push("-cp " + line);
            }
         }
      }
   }


   public function clone():Haxelib 
   {
      var haxelib = new Haxelib(name, version);
      return haxelib;
   }
}
