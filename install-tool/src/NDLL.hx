

class NDLL
{
   public var name:String;
   public var haxelib:String;
   public var srcDir:String;
   public var needsNekoApi:Bool;
   public var hash:String;

   static var mOS:String = neko.Sys.systemName();


   public function new(inName:String, inHaxelib:String,inNeedsNekoApi:Bool)
   {
      name = inName;
      if (inHaxelib=="" && InstallTool.isIphone())
         name = "lib" + inName;
      haxelib = inHaxelib;
      srcDir = "";
      hash = InstallTool.getID();
      needsNekoApi = inNeedsNekoApi;

      if (haxelib!="")
         srcDir = getHaxelib(haxelib);
   }

   static public function getHaxelib(inLibrary:String)
   {
      var proc = new neko.io.Process("haxelib", ["path", inLibrary ]);
      var result = "";
      try{
         while(true)
         {
            var line = proc.stdout.readLine();
            if (line.substr(0,1)!="-")
               result = line;
      }
      } catch (e:Dynamic) { };
      proc.close();
      //trace("Found " + haxelib + " at " + srcDir );
      if (result=="")
         throw("Could not find haxelib path  " + inLibrary + " - perhaps you need to install it?");
      return result;
   }

   public function copy(inPrefix:String, inDir:String, inCPP:Bool, inVerbose:Bool, ioAllFiles:Array<String>,?inOS:String)
   {
      var src=srcDir;
      var suffix = ".ndll";
      if (src=="")
      {
         if (inCPP)
         {
            src = getHaxelib("hxcpp") + "/bin/" +inPrefix;
            suffix = switch(inOS==null ? mOS : inOS)
               {
                  case "Windows","Windows64" : ".dll";
                  case "Linux","Linux64" : ".dso";
                  case "Mac","Mac64" : ".dylib";
                  default: ".so";
               };
         }
         else
            src = InstallTool.getNeko();
      }
      else
      {
         src += "/ndll/" + inPrefix;
         if (inOS=="android" || inOS=="webos") suffix = ".so";
      }

      if (inOS=="iphoneos" || inOS=="iphonesim")
         suffix = "." + inOS + ".a";

      src = src + name + suffix;
      if (!neko.FileSystem.exists(src))
      {
         throw ("Could not find ndll " + src + " required by project" );
      }
      var slash = src.lastIndexOf("/");
      var dest = inDir + "/" + src.substr(slash+1);
      InstallTool.copyIfNewer(src,dest,ioAllFiles,inVerbose);
   }
}

