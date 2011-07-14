using StringTools;
import format.swf.Data;
import format.swf.Constants;
import format.mp3.Data;
import format.wav.Data;
import nme.text.Font;



import nme.display.BitmapData;



class InstallTool
{
   static var mOS:String = neko.Sys.systemName();
   static var mTarget;

   public static function isMac() { return mOS.substr(0,3)=="Mac"; }
   public static function isIphone() { return mTarget=="iphone"; }
   public static function isLinux() { return mOS.substr(0,5)=="Linux"; }
   public static function isWindows() { return mOS.substr(0,3)=="Win"; }
   public static function dotSlash() { return isWindows() ? ".\\" : "./"; }

   static var mID = 1;
   static public function getID()
   {
      return StringTools.hex(mID++,8);
   }


   static function usage()
   {
      neko.Lib.println("Usage :  haxelib run nme [-v] COMMAND ...");
      neko.Lib.println(" COMMAND : copy-if-newer from to");
      neko.Lib.println(" COMMAND : update build.nmml [-DFLAG -Dname=val... ]");
      neko.Lib.println(" COMMAND : (update|build|run) [-debug] build.nmml target");
      neko.Lib.println(" COMMAND : uninstall build.nmml target");
   }

  public static function isNewer(inFrom:String, inTo:String, inVerbose:Bool) : Bool
  {
      if (inFrom==null || !neko.FileSystem.exists(inFrom))
      {
         throw("Error: " + inFrom + " does not exist");
         return false;
      }

      if (neko.FileSystem.exists(inTo))
      {
         if (neko.FileSystem.stat(inFrom).mtime.getTime() <
             neko.FileSystem.stat(inTo).mtime.getTime() )
         {
           if (inVerbose)
           {
                  neko.Lib.println(" no need: " + inFrom + "(" + 
                     neko.FileSystem.stat(inFrom).mtime.getTime()  + ") < " + inTo + " (" +
                     neko.FileSystem.stat(inTo).mtime.getTime() + ")" );
           }
           return false;
         }
      }
      return true;
   }

   public static function getNeko()
   {
      var n = neko.Sys.getEnv("NEKO_INSTPATH");
      if (n==null || n=="")
         n = neko.Sys.getEnv("NEKO_INSTALL_PATH");
      if (n==null || n=="")
         n = neko.Sys.getEnv("NEKOPATH");
      if (n==null || n=="")
      {
         if (isWindows())
           n = "C:/Motion-Twin/neko";
         else
           n = "/usr/lib/neko";
      }
      return n + "/";
   }



   public static function copyIfNewer(inFrom:String, inTo:String, ioAllFiles:Array<String>,inVerbose:Bool)
   {
      if (!isNewer(inFrom,inTo,inVerbose))
         return;
      ioAllFiles.push(inTo);
      if (inVerbose)
         neko.Lib.println("Copy " + inFrom + " to " + inTo );
      neko.io.File.copy(inFrom, inTo);
   }

   
   public static function main()
   {
      var words = new Array<String>();
      var defines = new Hash<String>();
      var include_path = new Array<String>();
      var command:String="";
      var verbose = false;
      var debug = false;

      include_path.push(".");

      var args = neko.Sys.args();
      var NME = "";
      // Check for calling from haxelib ...
      if (args.length>0)
      {
         var last:String = (new neko.io.Path(args[args.length-1])).toString();
         var slash = last.substr(-1);
         if (slash=="/"|| slash=="\\") 
            last = last.substr(0,last.length-1);
         if (neko.FileSystem.exists(last) && neko.FileSystem.isDirectory(last))
         {
            // When called from haxelib, the last arg is the original directory, and
            //  the current direcory is the library directory.
            NME = neko.Sys.getCwd();
            defines.set("NME",NME);
            args.pop();
            neko.Sys.setCwd(last);
         }
      }

      var os = neko.Sys.systemName();
      if ( (new EReg("window","i")).match(os) )
      {
         defines.set("windows", "1");
         defines.set("windows_host", "1");
         defines.set("HOST", "windows");
      }
      else if ( (new EReg("linux","i")).match(os) )
      {
         defines.set("linux","1");
         defines.set("HOST","linux");
      }
      else if ( (new EReg("mac","i")).match(os) )
      {
         defines.set("macos","1");
         defines.set("HOST","darwin-x86");
      }


      for(arg in args)
      {
         var equals = arg.indexOf("=");
         if (equals>0)
            defines.set(arg.substr(0,equals),arg.substr(equals+1));
         else if (arg=="-64")
            defines.set("NME_64","1");
         else if (arg.substr(0,2)=="-D")
            defines.set(arg.substr(2),"");
         else if (arg.substr(0,2)=="-I")
            include_path.push(arg.substr(2));
         else if (arg=="-v")
            verbose = true;
         else if (arg=="-debug")
            debug = true;
         else if (command.length==0)
            command = arg;
         else
            words.push(arg);
      }

      include_path.push(".");
      var env = neko.Sys.environment();
      if (env.exists("HOME"))
        include_path.push(env.get("HOME"));
      if (env.exists("USERPROFILE"))
        include_path.push(env.get("USERPROFILE"));
      include_path.push(NME + "/install-tool");


      var valid_commands = ["copy-if-newer", "rerun", "update", "test", "build", "installer", "uninstall"];
      if (!Lambda.exists(valid_commands,function(c) return command==c))
      {
         if (command!="")
            neko.Lib.println("Unknown command : " + command);
         usage();
         return;
      }

      if (command=="copy-if-newer")
      {
         if (words.length!=2)
         {
            neko.Lib.println("wrong number of arguements");
            usage();
            return;
         }
         copyIfNewer(words[0], words[1],[],verbose);
      }
      else
      {
         if (words.length!=2)
         {
            neko.Lib.println("wrong number of arguements");
            usage();
            return;
         }
 
         if (!neko.FileSystem.exists(words[0]))
         {
            neko.Lib.println("Error : " + command + ", .nmml file must be specified");
            usage();
            return;
         }

         for(e in env.keys())
            defines.set(e, neko.Sys.getEnv(e) );

         if ( !defines.exists("NME_CONFIG") )
            defines.set("NME_CONFIG",".hxcpp_config.xml");

         var tool:installer.Base = null;
         mTarget = words[1];
         switch(mTarget)
         {
            case "cpp" : tool = new installer.Cpp();
            case "neko" : tool = new installer.Neko();
            case "webos" : tool = new installer.Webos();
            case "iphone" : tool = new installer.IOS();
            case "flash" : tool = new installer.Flash();
            case "gph" : tool = new installer.Gph();
            case "android" : tool = new installer.Android();
            default:
              neko.Lib.println("Error : unknown target " + words[1]);
              return;
         }

         tool.process(NME,command,defines,include_path,words[0],words[1],verbose,debug);
      }
   }

}



